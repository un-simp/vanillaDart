class Response {
  final int id;
  final String command;
  final dynamic result;

  Response({
    required this.id,
    required this.command,
    this.result,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'command': command,
      'result': result,
    };
  }

  static Response fromJson(Map<String, dynamic> json) {
    return Response(
      id: json['id'],
      command: json['command'],
      result: json['result'],
    );
  }
}
