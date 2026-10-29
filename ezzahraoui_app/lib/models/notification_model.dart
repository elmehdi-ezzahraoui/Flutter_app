class NotificationModel {
  final String id;
  final String? userId;
  final String type; // 'new_report' | 'status_change' | 'upvote'
  final String title;
  final String? body;
  final String? reportId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    this.body,
    this.reportId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      type: json['type'] as String? ?? 'new_report',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      reportId: json['report_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      reportId: reportId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
