/* these are helper functions for use with the c library "Vanilla"
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

// bindings
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'vanilla_dart_bindings_generated.dart';

const String _libName = 'vanilla';
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final VanillaDartBindings _bindings = VanillaDartBindings(_dylib);

// this is what our client  instantiate and communicate with
class Backend{
  final SendPort _commands;
  final ReceivePort _responses;
  // for multi-requests
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter=0;
  bool _closed = false;

  static Future<Backend> spawn() async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
      ReceivePort.fromRawReceivePort(initPort),
      commandPort,
      ));};

    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }
    final (ReceivePort receivePort, SendPort sendPort) =
    await connection.future;

    return Backend._(receivePort, sendPort);
  }
  Backend._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

   void _handleResponsesFromIsolate(dynamic message) {
     final (int id, Object? response) = message as (int, Object?); // New
     final completer = _activeRequests.remove(id)!; // New

     if (response is RemoteError) {
       completer.completeError(response); // Updated
     } else {
       completer.complete(response); // Updated
     }
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  static void _handleCommandsToIsolate(
      ReceivePort receivePort, SendPort sendPort) {
    receivePort.listen((message) {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      final (int id, Map<String, String> data) = message as (int, Map<String, String>); // New
      try {
        sendPort.send((id, data)); // Updated
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  Future<Object?> makeRequest(Map<String,String> message) async{
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, message));
    return await completer.future;
  }


  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
      print('--- port closed --- ');
    }
  }

}



class IsolateBackend{
  late final ReceivePort receivePort;
  late final SendPort port;
  IsolateBackend(SendPort port){
    receivePort = ReceivePort();
    port.send(receivePort.sendPort);
    receivePort.listen((dynamic message) async {
      int resp = handleMessage(message);
      port.send(resp);
    });
  }

  int handleMessage(message) {
    switch (message['operation']) {
      case 'connect':
        final serverAddress = message['pipeAddress'];
        // not sure how ports work yet so stubbing this
        // final port = message['pipePort'];
        return connectToConsole(serverAddress);

    }
    return 0;


  }
// next implement an event handler for vanilla
  int connectToConsole(String serverAddress){
    return _bindings.vanilla_start_udp(Pointer.fromFunction(eventHandler), Pointer.fromAddress(this.port.nativePort), stripIP(serverAddress));
  }

  void endConsoleConnection(){
    _bindings.vanilla_stop();
  }

  static void eventHandler(Pointer<Void> context, int eventType, Pointer<Char> data, int dataSize){
    // convert the ports from our context then send any event we get and let the port receiver deal with it
   ReceivePort isolatePort = ReceivePort.fromRawReceivePort(context as RawReceivePort);
   SendPort sendPort = isolatePort.sendPort;
   sendPort.send({'event': eventType, 'data': data.toString(), 'dataSize': dataSize});
  }

}

class GamePad{




}


int stripIP(String ip){
  return ip.replaceAll(".", "") as int;
}
