import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

typedef hello_world_func = ffi.Void Function();
typedef HelloWorld = void Function();

class Olm {
  static void init() {
    var path = "../";
    var name = 'libhello.dylib';

    if (Platform.isMacOS) {
      name = 'libhello.dylib';
    }

    final dylib = ffi.DynamicLibrary.open(path);

    // Look up the C function 'hello_world'
    final HelloWorld hello = dylib
        .lookup<ffi.NativeFunction<hello_world_func>>('hello_world')
        .asFunction();
    // Call the function
    hello();
  }
}
