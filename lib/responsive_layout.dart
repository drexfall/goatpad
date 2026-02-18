import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget desktopLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    required this.desktopLayout,
  });

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 1200) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;
  static bool isDesktopOrTablet(BuildContext context) => !isMobile(context);

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobileLayout;
      case DeviceType.tablet:
        return tabletLayout ?? desktopLayout;
      case DeviceType.desktop:
        return desktopLayout;
    }
  }
}

