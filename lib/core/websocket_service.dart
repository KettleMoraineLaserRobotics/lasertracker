import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lasertracker/core/api.dart';
import 'package:lasertracker/core/database.dart';
import 'package:lasertracker/main.dart';
import 'package:lasertracker/models/models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WSSSatus { connecting, connected, disconnected, outdated }

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();
  WebSocketChannel? channel;
  final StreamController<WSMessage> eventController = StreamController<WSMessage>.broadcast();

  final ValueNotifier<WSSSatus> status = ValueNotifier(WSSSatus.disconnected);
  final ValueNotifier<bool> wantsConnection = ValueNotifier(false);

  Stream<WSMessage> get eventStream => eventController.stream;

  final Map<String, Completer<void>> pendingRequests = {};
  int requestCounter = 0;

  static const Map<String, String> errorText = {
    'invalid_payload': "The server didn't understand that request",
    'forbidden': "You don't have permission to do that",
    'not_found': "That member or item doesn't exist anymore",
    'already_exists': "That already exists",
    'unknown_type': "The server doesn't support that yet",
    'internal': "Something went wrong on the server",
  };

  int connectGen = 0;

  int failedUpgrades = 0;
  static const int maxFailedUpgrades = 3;

  static const int groupDeletedCloseCode = 4001;

  bool loggingOut = false;

  Future<void> handlerQueue = Future.value();

  Future<void> enqueue(Future<void> Function() job) {
    final next = handlerQueue.then((_) => job());
    handlerQueue = next.catchError((Object e) => debugPrint('ws handler failed: $e'));
    return next;
  }

  void connect(String jwtToken) async {
    final gen = ++connectGen;
    wantsConnection.value = true;
    loggingOut = false;
    final old = channel;
    channel = null;
    old?.sink.close();
    failPending("Lost connection to the server");
    status.value = WSSSatus.connecting;

    try {
      final requiredVersion = await getServerInfo();
      if (gen != connectGen) return;
      if (requiredVersion.isNotEmpty && requiredVersion != Hive.box('meta').get('client_version')) {
        status.value = WSSSatus.outdated;
        return;
      }
    } catch (_) {
      if (gen != connectGen) return;
      status.value = WSSSatus.disconnected;
      retryLater(gen);
      return;
    }

    final serverURL = Hive.box('meta').get('server_url');
    final wsUrl = Uri.parse(
      serverURL,
    ).replace(scheme: serverURL.startsWith('https') ? 'wss' : 'ws', path: '/ws', queryParameters: {'token': jwtToken});

    final ch = WebSocketChannel.connect(wsUrl);
    channel = ch;

    try {
      await ch.ready;
    } catch (_) {
      if (gen != connectGen) return;
      channel = null;
      status.value = WSSSatus.disconnected;
      if (++failedUpgrades >= maxFailedUpgrades) {
        forceLogout("Your login isn't valid anymore, please log in again.");
        return;
      }
      retryLater(gen);
      return;
    }
    if (gen != connectGen) {
      ch.sink.close();
      return;
    }
    failedUpgrades = 0;
    status.value = WSSSatus.connected;
    requestSync();

    ch.stream.listen(
      (message) {
        if (channel != ch) return;
        final WSMessage wsMessage;
        try {
          wsMessage = WSMessage.fromJson(jsonDecode(message as String) as Map<String, dynamic>);
        } catch (_) {
          return;
        }
        if (completeRequest(wsMessage)) return;
        eventController.add(wsMessage);
        handleWSPayload(wsMessage);
      },

      onError: (_) {
        if (channel == ch) status.value = WSSSatus.disconnected;
      },

      onDone: () {
        if (channel != ch) return;
        channel = null;
        status.value = WSSSatus.disconnected;
        failPending("Lost connection to the server");
        if (ch.closeCode == groupDeletedCloseCode) {
          forceLogout("The group you were in was deleted.", forgetGroup: true);
          return;
        }
        retryLater(gen);
      },
    );
  }

  Future<void> retryLater(int gen) async {
    await Future.delayed(const Duration(seconds: 3));
    if (gen != connectGen || !wantsConnection.value) return;
    final token = await const FlutterSecureStorage().read(key: 'token');
    if (gen != connectGen || token == null || token.isEmpty) return;
    connect(token);
  }

  void disconnect() {
    connectGen++;
    wantsConnection.value = false;
    final old = channel;
    channel = null;
    old?.sink.close();
    failPending("Disconnected");
  }

  Future<void> logOut({bool forgetGroup = false}) async {
    disconnect();
    failedUpgrades = 0;
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'token');
    await storage.delete(key: 'username');
    await storage.delete(key: 'pin');

    if (forgetGroup) await storage.delete(key: 'group_key');
    await enqueue(clearDB);
  }

  Future<void> forceLogout(String reason, {bool forgetGroup = false}) async {
    if (loggingOut) return;
    loggingOut = true;
    await logOut(forgetGroup: forgetGroup);
    router.go('/login');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = router.routerDelegate.navigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (dialogContext) => AlertDialog(
          title: Text('Logged out', style: Theme.of(dialogContext).textTheme.displaySmall),
          content: Text(reason),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ok'))],
        ),
      );
    });
  }

  void failPending(String reason) {
    if (pendingRequests.isEmpty) return;
    final pending = pendingRequests.values.toList();
    pendingRequests.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) completer.completeError(Exception(reason));
    }
  }

  void send(String infoType, {Map<String, dynamic>? payload, String? requestId}) {
    final ch = channel;
    if (ch == null) return;

    ch.sink.add(
      jsonEncode({
        'group_key': '',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'info_type': infoType,
        'payload': payload ?? {},
        'request_id': ?requestId,
      }),
    );
  }

  void requestSync() => send('SYNC');

  Future<void> sendRequest(String infoType, Map<String, dynamic> payload) {
    if (channel == null) {
      return Future.error(Exception("Not connected to the server"));
    }
    final requestId = "${DateTime.now().microsecondsSinceEpoch}-${requestCounter++}";
    final completer = Completer<void>();
    pendingRequests[requestId] = completer;
    send(infoType, payload: payload, requestId: requestId);
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        pendingRequests.remove(requestId);
        throw Exception("No response, you may be offline");
      },
    );
  }

  bool completeRequest(WSMessage message) {
    if (message.infoType != 'ACK' && message.infoType != 'ERROR') return false;
    final completer = pendingRequests.remove(message.requestId);
    if (completer == null) return true;
    if (message.infoType == 'ACK') {
      completer.complete();
    } else {
      final code = message.payload?['code'] as String?;
      completer.completeError(Exception(errorText[code] ?? message.payload?['message'] ?? "Request failed"));
    }
    return true;
  }

  void handleWSPayload(WSMessage message) => enqueue(() => dispatch(message));

  Future<void> dispatch(WSMessage message) async {
    // not awaited: logOut queues clearDB behind this job, awaiting it here would wait on itself forever
    if (message.infoType == 'GROUP_REMOVED') {
      unawaited(forceLogout("The group you were in was deleted.", forgetGroup: true));
      return;
    }
    if (message.payload == null) return;

    switch (message.infoType) {
      case 'SYNC':
        return handleSync(message);
      case 'MEMBER_ADDED':
      case 'MEMBER_UPDATED':
      case 'MEMBER_ROLE_CHANGED':
        return handleMember(message);
      case 'MEMBER_REMOVED':
        return handleMemberRemoved(message);
      case 'BATTERY_ADDED':
      case 'BATTERY_UPDATED':
        return handleBattery(message);
      case 'BATTERY_REMOVED':
        return handleBatteryRemoved(message);
      case 'GROUP_EVENT_KEY_UPDATED':
        return handleGroup(message);
      case 'MATCHES_UPDATED':
        return handleMatch(message);
      case 'STREAMS_UPDATED':
        return handleStreams(message);
      case 'LOG_ADDED':
        return handleLog(message);
    }
  }
}

List<Map<String, dynamic>> _asMapList(dynamic raw) =>
    (raw as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

String _logKey(LogEntry log) => log.timestamp!.toUtc().toIso8601String();

Future<void> putMember(Member member) => Hive.box('members').put(member.userName, member.toJson());

Future<void> putUser(User user) => Hive.box('user').put('user', user.toJson());

Future<void> putBattery(Battery battery) => Hive.box('batteries').put(battery.name, battery.toJson());

Future<void> putGroup(Group group) => Hive.box('group').put('group_info', group.toJson());

Future<void> putMatch(Match match) => Hive.box('matches').put(match.matchKey, match.toJson());

Future<void> putStream(EventStream stream) => Hive.box('streams').put(stream.url, stream.toJson());

Future<void> putLog(LogEntry log) => Hive.box('logs').put(_logKey(log), log.toJson());

Future<void> handleSync(WSMessage message) async {
  final data = message.payload!;
  final username = await const FlutterSecureStorage().read(key: "username");

  for (final box in ['members', 'batteries', 'logs', 'group', 'matches', 'streams']) {
    await Hive.box(box).clear();
  }

  for (final m in _asMapList(data['members'])) {
    final member = Member.fromJson(m);
    await putMember(member);
    if (member.userName == username) {
      await putUser(User.fromJson(m));
    }
  }
  for (final b in _asMapList(data['batteries'])) {
    await putBattery(Battery.fromJson(b));
  }
  for (final l in _asMapList(data['logs'])) {
    await putLog(LogEntry.fromJson(l));
  }
  if (data['group'] is Map) {
    await putGroup(Group.fromJson(Map<String, dynamic>.from(data['group'] as Map)));
  }
  for (final m in _asMapList(data['matches'])) {
    await putMatch(Match.fromJson(m));
  }
  for (final s in _asMapList(data['streams'])) {
    await putStream(EventStream.fromJson(s));
  }
}

Future<void> handleMember(WSMessage message) async {
  final member = Member.fromJson(message.payload!);
  await putMember(member);
  final username = await const FlutterSecureStorage().read(key: "username");
  if (member.userName == username) {
    await putUser(User.fromJson(message.payload!));
  }
}

Future<void> handleBattery(WSMessage message) => putBattery(Battery.fromJson(message.payload!));

Future<void> handleMemberRemoved(WSMessage message) =>
    Hive.box('members').delete(Member.fromJson(message.payload!).userName);

Future<void> handleBatteryRemoved(WSMessage message) =>
    Hive.box('batteries').delete(Battery.fromJson(message.payload!).name);

Future<void> handleGroup(WSMessage message) => putGroup(Group.fromJson(message.payload!));

Future<void> handleMatch(WSMessage message) async {
  final eventKey = message.payload!['event_key'];
  final box = Hive.box('matches');

  final incoming = <String, Map<String, dynamic>>{
    for (final m in _asMapList(message.payload!['matches']).map(Match.fromJson)) m.matchKey!: m.toJson(),
  };
  final stale = box.keys.where((k) {
    final existing = Match.fromJson(Map<String, dynamic>.from(box.get(k) as Map));
    return existing.eventKey == eventKey && !incoming.containsKey(k);
  }).toList();
  final changed = Map.fromEntries(incoming.entries.where((e) => !_sameJson(box.get(e.key), e.value)));

  if (stale.isNotEmpty) await box.deleteAll(stale);
  if (changed.isNotEmpty) await box.putAll(changed);
}

bool _sameJson(dynamic stored, Map<String, dynamic> fresh) =>
    stored is Map && jsonEncode(Map<String, dynamic>.from(stored)) == jsonEncode(fresh);

Future<void> handleStreams(WSMessage message) async {
  final box = Hive.box('streams');
  await box.clear();
  for (final s in _asMapList(message.payload!['streams'])) {
    await putStream(EventStream.fromJson(s));
  }
}

Future<void> handleLog(WSMessage message) => putLog(LogEntry.fromJson(message.payload!));
