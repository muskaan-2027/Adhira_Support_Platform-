import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  GoogleSignIn? _googleSignIn;

  bool _initialized = false;
  bool _loading = false;
  String? _token;
  AppUser? _currentUser;

  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get isAuthenticated => _token != null && _currentUser != null;
  String? get token => _token;
  AppUser? get currentUser => _currentUser;
  bool get isGoogleSignInConfigured => !kIsWeb || _googleWebClientId.isNotEmpty;

  GoogleSignIn _getGoogleSignIn() {
    if (kIsWeb && _googleWebClientId.isEmpty) {
      throw Exception(
        'Google sign-in is not configured. Pass --dart-define=GOOGLE_WEB_CLIENT_ID=... when running Flutter web.',
      );
    }

    _googleSignIn ??= GoogleSignIn(
      scopes: const ['email'],
      clientId: kIsWeb ? _googleWebClientId : null,
    );
    return _googleSignIn!;
  }

  bool get needsOnboarding {
    final user = _currentUser;
    if (user == null) return false;
    return !user.onboardingCompleted || user.name.trim().isEmpty;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final storedUser = prefs.getString(_userKey);

    if (storedToken != null && storedUser != null) {
      _token = storedToken;
      _currentUser = AppUser.fromJson(jsonDecode(storedUser) as Map<String, dynamic>);

      try {
        await refreshProfile();
      } catch (_) {
        await logout();
      }
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _withLoading(() async {
      final response = await ApiService.login(email: email, password: password);
      await _consumeAuthResponse(response);
    });
  }

  Future<void> register(String name, String email, String password, String role) async {
    await _withLoading(() async {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      await _consumeAuthResponse(response);
    });
  }

  Future<void> signInWithGoogle() async {
    await _withLoading(() async {
      final account = await _getGoogleSignIn().signIn();
      if (account == null) {
        throw Exception('Google sign-in cancelled');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Unable to fetch Google ID token');
      }

      final response = await ApiService.googleLogin(idToken);
      await _consumeAuthResponse(response);
    });
  }

  Future<void> refreshProfile() async {
    if (_token == null) {
      throw Exception('No auth token available');
    }

    final response = await ApiService.getProfile(_token!);
    final userMap = response['user'] as Map<String, dynamic>?;
    if (userMap == null) {
      throw Exception('Invalid profile response');
    }

    _currentUser = AppUser.fromJson(userMap);
    await _persistSession();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required bool voterIdVerified,
    required bool isAnonymous,
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
  }) async {
    if (_token == null) throw Exception('Not authenticated');

    await _withLoading(() async {
      final response = await ApiService.updateProfile(
        _token!,
        name: name,
        voterIdVerified: voterIdVerified,
        isAnonymous: isAnonymous,
        profilePhoto: profilePhoto,
        registrationId: registrationId,
        dateOfBirth: dateOfBirth,
        gender: gender,
        occupation: occupation,
        skills: skills,
        yearsOfExperience: yearsOfExperience,
        volunteerExperience: volunteerExperience,
        areasOfHelp: areasOfHelp,
        languagesKnown: languagesKnown,
        phone: phone,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        connectedToNGO: connectedToNGO,
        ngoName: ngoName,
        socialMediaLink: socialMediaLink,
        additionalInfo: additionalInfo,
      );
      final userMap = response['user'] as Map<String, dynamic>?;
      if (userMap == null) throw Exception('Invalid profile response');
      _currentUser = AppUser.fromJson(userMap);
      await _persistSession();
    });
  }

  Future<void> updateRole(String role) async {
    if (_token == null) throw Exception('Not authenticated');

    await _withLoading(() async {
      final response = await ApiService.updateRole(_token!, role);
      final userMap = response['user'] as Map<String, dynamic>?;
      if (userMap == null) throw Exception('Invalid role response');
      _currentUser = AppUser.fromJson(userMap);
      await _persistSession();
    });
  }

  Future<void> updatePreferences({
    bool? notifications,
    String? language,
    String? theme,
  }) async {
    if (_token == null) throw Exception('Not authenticated');

    await _withLoading(() async {
      final response = await ApiService.updatePreferences(
        _token!,
        notifications: notifications,
        language: language,
        theme: theme,
      );
      final userMap = response['user'] as Map<String, dynamic>?;
      if (userMap == null) throw Exception('Invalid preference response');
      _currentUser = AppUser.fromJson(userMap);
      await _persistSession();
    });
  }

  Future<void> updateVolunteerAvailability(String availability) async {
    if (_token == null) throw Exception('Not authenticated');

    await _withLoading(() async {
      await ApiService.updateVolunteerAvailability(_token!, availability);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(volunteerAvailability: availability);
        await _persistSession();
      }
    });
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (_) {
      // Sign-out failures should not block local logout.
    }

    notifyListeners();
  }

  Future<void> _consumeAuthResponse(Map<String, dynamic> response) async {
    final token = response['token']?.toString();
    final userMap = response['user'] as Map<String, dynamic>?;

    if (token == null || userMap == null) {
      throw Exception('Invalid authentication response');
    }

    _token = token;
    _currentUser = AppUser.fromJson(userMap);
    await _persistSession();
  }

  Future<void> _persistSession() async {
    if (_token == null || _currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
  }

  Future<void> _withLoading(Future<void> Function() action) async {
    _loading = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
