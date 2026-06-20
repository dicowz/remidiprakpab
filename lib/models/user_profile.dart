class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String instagram;
  final String profilePicUrl;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.instagram,
    required this.profilePicUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Space Traveler',
      email: json['email'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      profilePicUrl: json['profilePicUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'instagram': instagram,
      'profilePicUrl': profilePicUrl,
    };
  }
}
