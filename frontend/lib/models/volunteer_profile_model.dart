class VolunteerProfileModel {
  final String id;
  final String name;
  final String email;
  final String availability;
  final bool voterIdVerified;
  final String occupation;
  final double averageRating;
  final int totalRatings;
  final String gender;
  final String yearsOfExperience;
  final String areasOfHelp;
  final String city;
  final String state;
  final int followers;
  final int following;

  const VolunteerProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.availability,
    required this.voterIdVerified,
    required this.occupation,
    required this.averageRating,
    required this.totalRatings,
    required this.gender,
    this.yearsOfExperience = '',
    this.areasOfHelp = '',
    this.city = '',
    this.state = '',
    this.followers = 0,
    this.following = 0,
  });

  factory VolunteerProfileModel.fromJson(Map<String, dynamic> json) {
    return VolunteerProfileModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Volunteer',
      email: json['email']?.toString() ?? '',
      availability: json['volunteerAvailability']?.toString() ?? 'inactive',
      voterIdVerified: json['voterIdVerified'] == true,
      occupation: json['occupation']?.toString() ?? 'Volunteer',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      gender: json['gender']?.toString() ?? '',
      yearsOfExperience: json['yearsOfExperience']?.toString() ?? '',
      areasOfHelp: json['areasOfHelp']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      followers: (json['followers'] as List?)?.length ?? 0,
      following: (json['following'] as List?)?.length ?? 0,
    );
  }
}
