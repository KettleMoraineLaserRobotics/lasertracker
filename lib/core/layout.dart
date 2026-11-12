import 'package:flutter/widgets.dart';

const double wideBreakpoint = 1000;

bool isWideScreen(BuildContext context) => MediaQuery.sizeOf(context).width >= wideBreakpoint;
