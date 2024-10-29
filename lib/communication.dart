/* Communication Layer for the Vanilla Isolate
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

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

class VanillaCommunication{

  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int,Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;

  Future<Object?> parseJson(String message) async {
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id,message));
    return await completer.future;
  }

  static Future<VanillaCommunication> spawn() async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort,SendPort)>.sync();
    initPort.handler = (initialMessage){
      final commandPort = initialMessage as SendPort;
      connection.complete((ReceivePort.fromRawReceivePort(initPort),commandPort));
    };
    // attempt isolate spawn
    try
    {
      await Isolate.spawn(_startRemoteIsolate,(initPort.sendPort));
    } on Object
    {
      initPort.close();
      rethrow;
    }
    final (ReceivePort recievePort, SendPort sendPort) = await connection.future;

    return VanillaCommunication._(recievePort,sendPort);

  }


  VanillaCommunication._(this._responses, this._commands){
    _responses.listen(_handleResponsesFromIsolate);
  }


void _handleResponsesFromIsolate(dynamic message){
    if (message is RemoteError){
      throw message;
    } else {
      print(message);
    }

}
static void _handleCommandsToIsolate(ReceivePort rp, SendPort sp) async{
    rp.listen((message) {
      try{
        final jsonData = jsonDecode(message as String);
        sp.send(jsonData)
      } catch (e){
        sp.send(RemoteError(e.toString(),''));
      }
    });

}
static void _startRemoteIsolate(SendPort sp){
    final receivePort = ReceivePort();
    // give main isolate the sendport
    sp.send(receivePort.sendPort);
}

}