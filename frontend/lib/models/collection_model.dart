class CollectionModel {
  final String id;
  final String userId;
  final String name;
  final String startDate;
  final String endDate;
  final String createdAt;

  const CollectionModel({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.startDate = '',
    this.endDate = '',
    this.createdAt = '',
  });

  factory CollectionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CollectionModel(
      id: docId ?? map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      startDate: map['start_date'] ?? '',
      endDate: map['end_date'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'created_at': createdAt,
      };
}
