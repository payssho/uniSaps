enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequestModel {
  final String id;
  final String fromUid;
  final String toUid;
  final String fromUsername;
  final String fromPhotoUrl;
  final String toUsername;
  final String toPhotoUrl;
  final FriendRequestStatus status;
  final String createdAt;

  const FriendRequestModel({
    this.id = '',
    this.fromUid = '',
    this.toUid = '',
    this.fromUsername = '',
    this.fromPhotoUrl = '',
    this.toUsername = '',
    this.toPhotoUrl = '',
    this.status = FriendRequestStatus.pending,
    this.createdAt = '',
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return FriendRequestModel(
      id: docId ?? map['id'] ?? '',
      fromUid: map['from_uid'] ?? '',
      toUid: map['to_uid'] ?? '',
      fromUsername: map['from_username'] ?? '',
      fromPhotoUrl: map['from_photo_url'] ?? '',
      toUsername: map['to_username'] ?? '',
      toPhotoUrl: map['to_photo_url'] ?? '',
      status: _parseStatus(map['status']),
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'from_uid': fromUid,
        'to_uid': toUid,
        'from_username': fromUsername,
        'from_photo_url': fromPhotoUrl,
        'to_username': toUsername,
        'to_photo_url': toPhotoUrl,
        'status': status.name,
        'created_at': createdAt,
      };

  static FriendRequestStatus _parseStatus(dynamic val) {
    if (val == 'accepted') return FriendRequestStatus.accepted;
    if (val == 'rejected') return FriendRequestStatus.rejected;
    return FriendRequestStatus.pending;
  }
}
