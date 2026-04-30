class EmergencyContact {
  final String id;
  final String name;
  final String phone;

  EmergencyContact({required this.id, required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
    };
  }
}

class UserPreferences {
  final bool notifications;
  final String language;
  final String theme;

  UserPreferences({
    this.notifications = true,
    this.language = 'English',
    this.theme = 'Light',
  });

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserPreferences();
    return UserPreferences(
      notifications: json['notifications'] == true,
      language: json['language']?.toString() ?? 'English',
      theme: json['theme']?.toString() ?? 'Light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications,
      'language': language,
      'theme': theme,
    };
  }

  UserPreferences copyWith({
    bool? notifications,
    String? language,
    String? theme,
  }) {
    return UserPreferences(
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? role;
  final bool onboardingCompleted;
  final bool voterIdVerified;
  final String volunteerAvailability;
  final bool isAnonymous;

  // New Volunteer Profile Fields
  final String? profilePhoto;
  final String? registrationId;
  final String? dateOfBirth;
  final String? gender;
  final String? occupation;
  final String? skills;
  final String? yearsOfExperience;
  final String? volunteerExperience;
  final String? areasOfHelp;
  final List<String> languagesKnown;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final bool connectedToNGO;
  final String? ngoName;
  final String? socialMediaLink;
  final String? additionalInfo;

  final double averageRating;
  final int totalRatings;
  final List<EmergencyContact> emergencyContacts;
  final UserPreferences preferences;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.onboardingCompleted,
    required this.voterIdVerified,
    required this.volunteerAvailability,
    required this.isAnonymous,
    this.profilePhoto,
    this.registrationId,
    this.dateOfBirth,
    this.gender,
    this.occupation,
    this.skills,
    this.yearsOfExperience,
    this.volunteerExperience,
    this.areasOfHelp,
    this.languagesKnown = const [],
    this.phone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.connectedToNGO = false,
    this.ngoName,
    this.socialMediaLink,
    this.additionalInfo,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.emergencyContacts = const [],
    required this.preferences,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
      onboardingCompleted: json['onboardingCompleted'] == true,
      voterIdVerified: json['voterIdVerified'] == true,
      volunteerAvailability: json['volunteerAvailability']?.toString() ?? 'inactive',
      isAnonymous: json['isAnonymous'] == true,
      profilePhoto: json['profilePhoto']?.toString(),
      registrationId: json['registrationId']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      occupation: json['occupation']?.toString(),
      skills: json['skills']?.toString(),
      yearsOfExperience: json['yearsOfExperience']?.toString(),
      volunteerExperience: json['volunteerExperience']?.toString(),
      areasOfHelp: json['areasOfHelp']?.toString(),
      languagesKnown: (json['languagesKnown'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      connectedToNGO: json['connectedToNGO'] == true,
      ngoName: json['ngoName']?.toString(),
      socialMediaLink: json['socialMediaLink']?.toString(),
      additionalInfo: json['additionalInfo']?.toString(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preferences: UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>?),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'onboardingCompleted': onboardingCompleted,
      'voterIdVerified': voterIdVerified,
      'volunteerAvailability': volunteerAvailability,
      'isAnonymous': isAnonymous,
      'profilePhoto': profilePhoto,
      'registrationId': registrationId,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'occupation': occupation,
      'skills': skills,
      'yearsOfExperience': yearsOfExperience,
      'volunteerExperience': volunteerExperience,
      'areasOfHelp': areasOfHelp,
      'languagesKnown': languagesKnown,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'connectedToNGO': connectedToNGO,
      'ngoName': ngoName,
      'socialMediaLink': socialMediaLink,
      'additionalInfo': additionalInfo,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'preferences': preferences.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    bool? onboardingCompleted,
    bool? voterIdVerified,
    String? volunteerAvailability,
    bool? isAnonymous,
    String? profilePhoto,
    String? registrationId,
    String? dateOfBirth,
    String? gender,
    String? occupation,
    String? skills,
    String? yearsOfExperience,
    String? volunteerExperience,
    String? areasOfHelp,
    List<String>? languagesKnown,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    bool? connectedToNGO,
    String? ngoName,
    String? socialMediaLink,
    String? additionalInfo,
    double? averageRating,
    int? totalRatings,
    List<EmergencyContact>? emergencyContacts,
    UserPreferences? preferences,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      voterIdVerified: voterIdVerified ?? this.voterIdVerified,
      volunteerAvailability: volunteerAvailability ?? this.volunteerAvailability,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      registrationId: registrationId ?? this.registrationId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      skills: skills ?? this.skills,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      volunteerExperience: volunteerExperience ?? this.volunteerExperience,
      areasOfHelp: areasOfHelp ?? this.areasOfHelp,
      languagesKnown: languagesKnown ?? this.languagesKnown,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      connectedToNGO: connectedToNGO ?? this.connectedToNGO,
      ngoName: ngoName ?? this.ngoName,
      socialMediaLink: socialMediaLink ?? this.socialMediaLink,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      preferences: preferences ?? this.preferences,
    );
  }
}
