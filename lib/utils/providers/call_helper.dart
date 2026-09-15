import 'dart:developer';

import 'package:flutter/foundation.dart';

mixin CallHelper on ChangeNotifier {
  void call<T>({
    required void Function(bool) setLoading,
    required Function() onCall,
  }) {
    try {
      setLoading(true);
      notifyListeners();
      onCall.call();
      setLoading(false);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        log(e.toString());
      }
    }
  }

  void callLoadAsync<T>(
      {required void Function(bool) setLoading,
      required Future<void> Function() onCall}) async {
    try {
      setLoading(true);
      notifyListeners();
      await onCall.call();
      setLoading(false);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        log('error => $e');
      }
    }
  }

  Future<T> callAsync<T>({
    required Future<T> Function() onCall,
  }) async {
    try {
      return onCall.call();
    } catch (e) {
      if (kDebugMode) {
        log(e.toString());
      }
      rethrow;
    }
  }
}
