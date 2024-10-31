import 'dart:io';
import 'package:vanillaDart/communication.dart';
void main() async{
  final worker = await VanillaCommunication.spawn();
  // default dart shit
  //  print(await worker.sendMsg('{"key":"value"}'));
  // print(await worker.sendMsg('"balls"'));
  // print(await worker.sendMsg('[true,false,null,1,"string"]'));
  // print(await Future.wait([worker.sendMsg('"yes"'), worker.sendMsg('"no"')]));
  // worker.close();
  // print(await worker.sendMsg('{"key":"value"}'));
  // var req = await worker.sendMsg('parseJson',data: '{"key":"value"}' );
  // print(req.result);
  // var audio = await worker.sendMsg("audioTest");
  // var outFile = File("/home/un/out.mp3");
  //outFile.writeAsBytes(audio.result);
  print(Directory.current);
  var connection = await worker.sendMsg("connect");
  print(connection.result);
  sleep(Duration(seconds: 10));
  await worker.sendMsg("stop");
  print("ended");



}