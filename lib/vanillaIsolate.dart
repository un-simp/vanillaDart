/* functions that convert from libvanilla to dart
  Copyright (C) 2024 unsimp

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */



import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:vanillaDart/util/Requests/request.dart';
import 'package:vanillaDart/util/Responses/response.dart';
import 'package:vanillaDart/vanilla_ffigen.dart';

class VanillaIsolate {
  late final VanillaDartBindings _bindings;
  late SendPort _port;
  
  // Loads the library on instantiation
  VanillaIsolate(SendPort port) {
    final DynamicLibrary dylib = () {
      if (Platform.isMacOS || Platform.isIOS) {
        return DynamicLibrary.open('vanilla.framework/vanilla');
      }
      if (Platform.isAndroid || Platform.isLinux) {
        return DynamicLibrary.open('libvanilla.so');
      }
      if (Platform.isWindows) {
        return DynamicLibrary.open('vanilla.dll');
      }
      throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
    }();
    // The bindings to the native functions in [_dylib].
    _bindings = VanillaDartBindings(dylib);
    _port = port;
  }
  
  void messageHandler(Map<String, dynamic> message) {
    try {
      final request = Request.fromJson(message);
      final int id = request.id;
      final String command = request.command;
      final dynamic data = request.data;
  
      switch (command) {
        case 'connect':
          _port.send(Response(id: id, command: "connect", result: vanillaStart()).toJson());
          break;
        case 'audioTest':
          final file = File("/home/un/Music/courage.mp3");
          _port.send(Response(id: id, command: "audioData",result: Uint8List.fromList(file.readAsBytesSync())).toJson());
          break;
        default:
          _port.send(Response(id: id, command: 'error', result: 'Unknown command: $command').toJson());
          break;
      }
    } catch (e, stack) {
      final int id = message['id'];
      _port.send(Response(id: id, command: 'error', result: RemoteError(e.toString(), stack.toString())).toJson());
    }
  }
  
  int vanillaStart(){
    final eventHandlerPointer = Pointer.fromFunction<vanilla_event_handler_tFunction>(eventHandler);
    return _bindings.vanilla_start(eventHandlerPointer, nullptr);
  }

  static void eventHandler(Pointer<Void> context, int event_type, Pointer<Char> data, int data_size){
    final message = data.toString();
    print('Event type: $event_type, Data: $message, Size: $data_size');
  }

}
