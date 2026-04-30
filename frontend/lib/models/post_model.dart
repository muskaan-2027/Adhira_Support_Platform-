class PostModel {
  final String id;
  String content;
  final String caption;
  final String mediaUrl;
  final String mediaType;
  final bool isAnonymous;
  final String mode;
  final String field;
  final String distressLevel;
  final String urgencyColor;
  final String toxicityLevel;
  bool isDeleted;
  final String deletedReason;
  List<String> likes;
  final int views;
  int commentCount;
  List<String> readBy;
  final bool isRepost;
  final String originalAuthorName;
  final Map<String, dynamic>? user;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.content,
    required this.caption,
    required this.mediaUrl,
    required this.mediaType,
    required this.isAnonymous,
    required this.mode,
    required this.field,
    required this.distressLevel,
    required this.urgencyColor,
    required this.toxicityLevel,
    required this.isDeleted,
    required this.deletedReason,
    required this.likes,
    required this.views,
    required this.commentCount,
    required this.readBy,
    required this.isRepost,
    required this.originalAuthorName,
    this.user,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? 'text',
      isAnonymous: json['isAnonymous'] == true,
      mode: json['mode']?.toString() ?? 'public',
      field: json['field']?.toString() ?? '',
      distressLevel: json['distressLevel']?.toString() ?? 'normal',
      urgencyColor: json['urgencyColor']?.toString() ?? 'green',
      toxicityLevel: json['toxicityLevel']?.toString() ?? 'low',
      isDeleted: json['isDeleted'] == true,
      deletedReason: json['deletedReason']?.toString() ?? '',
      likes: (json['likes'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      views: json['views'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      readBy: (json['readBy'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      isRepost: json['isRepost'] == true,
      originalAuthorName: json['originalAuthorName']?.toString() ?? '',
      user: json['userId'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
