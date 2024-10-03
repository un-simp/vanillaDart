
import '../../lib/vanilla_dart.dart';

void main() async {
 // start the isolate/vanilla
 final backend = await Backend.spawn();


  // send some example data (connect to pipe on ip 192.168.1.109 and with initial port 8096)
  backend.makeRequest({'operation': 'connect', 'pipeAddress': '192.168.1.109','pipePort': '8096'});

  backend.close();
 backend.makeRequest({'operation': 'connect', 'pipeAddress': '192.168.1.109','pipePort': '8096'});


}
