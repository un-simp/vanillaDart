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
import 'dart:isolate';

import 'package:vanillaDart/util/Requests/request.dart';
import 'package:vanillaDart/util/Responses/response.dart';
import 'package:vanillaDart/vanillaIsolate.dart';
class VanillaCommunication {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Response>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  Future<Response> sendMsg(String command, {dynamic data}) async {
    if (_closed) throw StateError("CLOSED");
    final completer = Completer<Response>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final request = Request(id: id, command: command, data: data);

    _commands.send(request.toJson());
    return await completer.future;
  }

  static Future<VanillaCommunication> spawn() async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
    };

    // Attempt to spawn isolate
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

    return VanillaCommunication._(receivePort, sendPort);
  }

  VanillaCommunication._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    assert(message is Map<String, dynamic>);
    final response = Response.fromJson(message);
    final completer = _activeRequests.remove(response.id)!;

    if (response.result is RemoteError) {
      completer.completeError(response.result);
    } else {
      _responseHandler(response);
      completer.complete(response);
    }
  }
  void _responseHandler(Response response){

    switch (response.command){
      case "stop":
        close();

    }
    return;
  }
  static void _handleCommandsToIsolate(ReceivePort rp, SendPort sp) {
    VanillaIsolate handler = VanillaIsolate(sp);
    rp.listen((message) {
      if (message is Map<String, dynamic> && message['command'] == 'shutdown') {
        rp.close();
        return;
      }
      handler.messageHandler(message);
    });
  }

  static void _startRemoteIsolate(SendPort sp) {
    final receivePort = ReceivePort();
    // Give main isolate the sendport
    sp.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sp);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send(Request(id: 0, command: "shutdown").toJson());
      if (_activeRequests.isEmpty) _responses.close();
      print("PORT CLOSED");
    }
  }
}
