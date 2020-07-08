package org.tether.tether 

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback 
import com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin;
import android.util.Log

public class Application: FlutterApplication(), PluginRegistrantCallback {
  override fun onCreate() {
    super.onCreate() 

  }

  override fun registerWith(registry: PluginRegistry) { 
    // https://github.com/mogol/flutter_secure_storage/issues/126
    // ##2## and registrar since type param was  PluginRegistrar (and not PluginRegistry)
    FlutterSecureStoragePlugin.registerWith(registry.registrarFor("com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin"))
  }
}