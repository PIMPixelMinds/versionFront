class Notifications {
  final String title;
  final String message;
  final DateTime createdAt;

  Notifications({
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      title: json['title'] ?? "",
      message: json['message'] ?? "",
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
