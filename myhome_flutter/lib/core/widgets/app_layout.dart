import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared widths adapt to the viewport while keeping long text readable.
class AppLayout {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static bool wide(BuildContext context) => width(context) >= 1100;
  static double formWidth(BuildContext context) =>
      math.min(1240, width(context) * (wide(context) ? .76 : .96));
  static double contentWidth(BuildContext context) =>
      math.min(1660, width(context) * .96);
  static double readingWidth(BuildContext context) =>
      math.min(1100, width(context) * .96);
  static double authWidth(BuildContext context) =>
      math.min(640, width(context) * .96);
  static double actionWidth(BuildContext context, double available) =>
      available >= 600
      ? available * .32
      : available < 360
      ? available
      : (available - 12) / 2;
  static double gutter(BuildContext context) => wide(context) ? 32 : 20;
}

/// A common body frame covers screens that otherwise stretch edge to edge.
/// Native Scaffold remains responsible for navigation, keyboard and safe areas.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body, drawer, bottomNavigationBar, floatingActionButton;
  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    drawer: drawer,
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
    body: body == null
        ? null
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppLayout.contentWidth(context),
              ),
              child: body,
            ),
          ),
  );
}
