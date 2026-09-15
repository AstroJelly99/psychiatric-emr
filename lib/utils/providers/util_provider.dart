import 'dart:math';

import 'package:flutter/material.dart';
import 'package:emr_homemade/utils/providers/call_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UtilProvider with ChangeNotifier, CallHelper {
  UtilProvider(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    getPackageInfo();
  }
  late double screenWidth;
  late double screenHeight;

  bool fetchingPackage = false;
  late PackageInfo systemInfo;
  Future<void> getPackageInfo() async => callLoadAsync(
      setLoading: (v) => fetchingPackage = v,
      onCall: () async {
        systemInfo = await PackageInfo.fromPlatform();
      });
}

class Scaler {
  static double textScaleFactor(BuildContext context,
      {double maxTextScaleFactor = 2}) {
    final width = MediaQuery.of(context).size.width;
    double val = (width / 1400) * maxTextScaleFactor;
    return max(1, min(val, maxTextScaleFactor));
  }
}
