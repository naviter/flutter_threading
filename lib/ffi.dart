import "dart:ffi";

class FfiUtilsInterface {
  FfiUtilsInterface() {
    _lib = DynamicLibrary.open(libraryPath);
    _utils = UtilsInterface(_lib);
    _isLoaded = true;
  }

  static String get libraryPath => 'libffiutils.so';

  void dispose() {
    _utils.dispose();
    _isLoaded = false;
  }

  UtilsInterface get utils => _isLoaded ? _utils : throw StateError('FFI Utils not loaded');

  bool _isLoaded = false;
  late DynamicLibrary _lib;
  late UtilsInterface _utils;
}

// ignore_for_file: avoid_private_typedef_functions
typedef _GetThreadIdNatFunc = Int64 Function();
typedef _GetThreadIdFunc = int Function();

class UtilsInterface {
  UtilsInterface(this._lib) {
    _getThreadId = _lib.lookupFunction<_GetThreadIdNatFunc, _GetThreadIdFunc>('getThreadId');
  }

  void dispose() {
  }

  int getThreadId() => _getThreadId();

  late final _GetThreadIdFunc _getThreadId;

  final DynamicLibrary _lib;
}
