
class Moment {
  final String imageUrl;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? location;
  final DateTime createdAt;

  Moment({
    required this.imageUrl,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.location,
    required this.createdAt,
  });
}
