class HelpRequestModel {
  final String id;
  final String message;
  final String status;
  final String requesterName;
  final String? volunteerName;
  final String assistanceNote;
  final int rating;
  final String ratingReview;
  final DateTime? createdAt;
  final List<FollowUpModel> followUps;

  const HelpRequestModel({
    required this.id,
    required this.message,
    required this.status,
    required this.requesterName,
    required this.volunteerName,
    required this.assistanceNote,
    required this.rating,
    required this.ratingReview,
    required this.createdAt,
    required this.followUps,
  });

  factory HelpRequestModel.fromJson(Map<String, dynamic> json) {
    final requester = json['requesterId'] is Map<String, dynamic>
        ? json['requesterId'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final volunteer = json['volunteerId'] is Map<String, dynamic>
        ? json['volunteerId'] as Map<String, dynamic>
        : const <String, dynamic>{};
    
    final followUpsRaw = json['followUps'] as List<dynamic>? ?? [];
    final followUps = followUpsRaw
        .whereType<Map<String, dynamic>>()
        .map(FollowUpModel.fromJson)
        .toList();

    return HelpRequestModel(
      id: json['_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requesterName: requester['name']?.toString() ?? 'Unknown User',
      volunteerName: volunteer['name']?.toString(),
      assistanceNote: json['assistanceNote']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      ratingReview: json['ratingReview']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      followUps: followUps,
    );
  }
}

class FollowUpModel {
  final String senderName;
  final String message;
  final DateTime createdAt;

  const FollowUpModel({
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    final sender = json['senderId'] is Map<String, dynamic>
        ? json['senderId'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return FollowUpModel(
      senderName: sender['name']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
