class Request {
  final int id;
  final String command;
  final dynamic data;

  Request({
    required this.id,
    required this.command,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'command': command,
      'data': data ?? {},
    };
  }

  static Request fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'],
      command: json['command'],
      data: json['data'],
    );
  }
}