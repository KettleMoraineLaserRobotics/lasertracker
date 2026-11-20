library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lasertracker/core/websocket_service.dart';

part 'battery.dart';
part 'group.dart';
part 'log_entry.dart';
part 'match.dart';
part 'event_stream.dart';
part 'member.dart';
part 'user.dart';
part 'ws_message.dart';

DateTime? _parseTime(dynamic v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
int? _asInt(dynamic v) => (v as num?)?.toInt();
