import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static final String baseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps host loopback via 10.0.2.2.
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    late http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'PATCH') {
      response = await http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers);
    } else {
      response = await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    }

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
    if (response.statusCode >= 400) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ?? 'Request failed'
          : response.body;
      throw Exception(message);
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'data': decoded};
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _request('POST', '/api/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _request('POST', '/api/auth/login', body: {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> googleLogin(String idToken) {
    return _request('POST', '/api/auth/google', body: {'idToken': idToken});
  }

  static Future<Map<String, dynamic>> getProfile(String token) {
    return _request('GET', '/api/users/me', token: token);
  }

  static Future<Map<String, dynamic>> searchUsers(String token, String query) {
    return _request('GET', '/api/users/search?query=${Uri.encodeComponent(query)}', token: token);
  }

  static Future<Map<String, dynamic>> updateProfile(
    String token, {
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
  }) {
    return _request('PATCH', '/api/users/profile', token: token, body: {
      'name': name,
      'voterIdVerified': voterIdVerified,
      'isAnonymous': isAnonymous,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      if (registrationId != null) 'registrationId': registrationId,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (occupation != null) 'occupation': occupation,
      if (skills != null) 'skills': skills,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (volunteerExperience != null) 'volunteerExperience': volunteerExperience,
      if (areasOfHelp != null) 'areasOfHelp': areasOfHelp,
      if (languagesKnown != null) 'languagesKnown': languagesKnown,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (connectedToNGO != null) 'connectedToNGO': connectedToNGO,
      if (ngoName != null) 'ngoName': ngoName,
      if (socialMediaLink != null) 'socialMediaLink': socialMediaLink,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    });
  }

  static Future<Map<String, dynamic>> updateRole(String token, String role) {
    return _request('PATCH', '/api/users/role', token: token, body: {'role': role});
  }

  static Future<Map<String, dynamic>> updatePreferences(
    String token, {
    bool? notifications,
    String? language,
    String? theme,
  }) {
    return _request('PATCH', '/api/users/preferences', token: token, body: {
      if (notifications != null) 'notifications': notifications,
      if (language != null) 'language': language,
      if (theme != null) 'theme': theme,
    });
  }

  static Future<Map<String, dynamic>> changePassword(String token, String oldPassword, String newPassword) {
    return _request('PATCH', '/api/users/password', token: token, body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  static Future<Map<String, dynamic>> updateVolunteerAvailability(String token, String availability) {
    return _request('PATCH', '/api/volunteers/availability', token: token, body: {'availability': availability});
  }

  static Future<Map<String, dynamic>> sendSOS(
    String token, {
    required double lat,
    required double lng,
    String notes = '',
  }) {
    return _request('POST', '/api/sos', token: token, body: {
      'lat': lat,
      'lng': lng,
      'notes': notes,
    });
  }

  static Future<Map<String, dynamic>> getSOSHistory(String token) {
    return _request('GET', '/api/sos/history', token: token);
  }

  static Future<Map<String, dynamic>> createHelpRequest(
    String token, {
    required String message,
    String? sosId,
    String? volunteerId,
  }) {
    return _request('POST', '/api/help-requests', token: token, body: {
      'message': message,
      if (sosId != null) 'sosId': sosId,
      if (volunteerId != null) 'volunteerId': volunteerId,
    });
  }

  static Future<Map<String, dynamic>> getHelpRequests(String token) {
    return _request('GET', '/api/help-requests', token: token);
  }

  static Future<Map<String, dynamic>> updateHelpRequestStatus(
    String token,
    String requestId,
    String status,
    {String? assistanceNote, int? hoursSpent, int? peopleHelped}
  ) {
    return _request('PATCH', '/api/help-requests/$requestId/status', token: token, body: {
      'status': status,
      if (assistanceNote != null) 'assistanceNote': assistanceNote,
      if (hoursSpent != null) 'hoursSpent': hoursSpent,
      if (peopleHelped != null) 'peopleHelped': peopleHelped,
    });
  }

  static Future<Map<String, dynamic>> rateHelpRequest(
    String token,
    String requestId,
    int rating,
    String review,
  ) {
    return _request('POST', '/api/help-requests/$requestId/rate', token: token, body: {
      'rating': rating,
      'review': review,
    });
  }

  static Future<Map<String, dynamic>> addHelpRequestFollowUp(
    String token,
    String requestId,
    String message,
  ) {
    return _request('POST', '/api/help-requests/$requestId/follow-up', token: token, body: {
      'message': message,
    });
  }

  static Future<Map<String, dynamic>> getVolunteerProfiles(
    String token, {
    bool onlyActive = true,
  }) {
    return _request(
      'GET',
      '/api/volunteers?onlyActive=${onlyActive ? "true" : "false"}',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> suggestVolunteers(
    String token,
    String issue,
  ) {
    return _request(
      'GET',
      '/api/volunteers/suggest?issue=${Uri.encodeQueryComponent(issue)}',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> rateVolunteerProfile(
    String token,
    String volunteerId,
    int rating,
    String review,
  ) {
    return _request('POST', '/api/volunteers/$volunteerId/rate', token: token, body: {
      'rating': rating,
      'review': review,
    });
  }

  static Future<Map<String, dynamic>> analyzePost(
    String token, {
    required String content,
  }) {
    return _request(
      'POST',
      '/api/posts/analyze',
      token: token,
      body: {'content': content},
    );
  }

  static Future<Map<String, dynamic>> createPost(
    String token, {
    required String content,
    required bool isAnonymous,
    String mode = 'public',
    String field = '',
    String caption = '',
    String mediaUrl = '',
    String mediaType = 'text',
  }) {
    return _request('POST', '/api/posts', token: token, body: {
      'content': content,
      'isAnonymous': isAnonymous,
      'mode': mode,
      'field': field,
      if (caption.isNotEmpty) 'caption': caption,
      if (mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
      if (mediaType != 'text') 'mediaType': mediaType,
    });
  }

  static Future<Map<String, dynamic>> getPosts(String token, {String? tab}) {
    final path = tab != null && tab.isNotEmpty
        ? '/api/posts?tab=${Uri.encodeComponent(tab)}'
        : '/api/posts';
    return _request('GET', path, token: token);
  }

  static Future<Map<String, dynamic>> incrementView(String token, String postId) {
    return _request('POST', '/api/posts/$postId/view', token: token);
  }

  static Future<Map<String, dynamic>> likePost(String token, String postId) {
    return _request('POST', '/api/posts/$postId/like', token: token);
  }

  static Future<Map<String, dynamic>> unlikePost(String token, String postId) {
    return _request('POST', '/api/posts/$postId/unlike', token: token);
  }

  static Future<Map<String, dynamic>> addComment(String token, String postId, String content) {
    return _request('POST', '/api/posts/$postId/comments', token: token, body: {'content': content});
  }

  static Future<Map<String, dynamic>> getComments(String token, String postId) {
    return _request('GET', '/api/posts/$postId/comments', token: token);
  }

  static Future<Map<String, dynamic>> markPostRead(String token, String postId) {
    return _request('POST', '/api/posts/$postId/read', token: token);
  }

  static Future<Map<String, dynamic>> acceptPrivateRequest(String token, String postId) {
    return _request('POST', '/api/private-chat/accept/$postId', token: token);
  }

  static Future<Map<String, dynamic>> getPrivateSessions(String token) {
    return _request('GET', '/api/private-chat/sessions', token: token);
  }

  static Future<Map<String, dynamic>> sendPrivateMessage(String token, String sessionId, String content) {
    return _request('POST', '/api/private-chat/$sessionId/messages', token: token, body: {'content': content});
  }

  static Future<Map<String, dynamic>> getPrivateMessages(String token, String sessionId) {
    return _request('GET', '/api/private-chat/$sessionId/messages', token: token);
  }

  static Future<Map<String, dynamic>> chatbot({
    required String message,
    required String language,
    required List<Map<String, String>> history,
  }) {
    return _request('POST', '/api/chatbot', body: {
      'message': message,
      'language': language,
      'history': history,
    });
  }

  static Future<Map<String, dynamic>> getNotifications(String token) {
    return _request('GET', '/api/notifications', token: token);
  }

  static Future<Map<String, dynamic>> markNotificationsRead(String token) {
    return _request('PATCH', '/api/notifications/mark-read', token: token);
  }

  static Future<Map<String, dynamic>> getCommunityStories(String token) {
    return _request('GET', '/api/community/stories', token: token);
  }

  static Future<Map<String, dynamic>> getCommunityBlogs(String token, {String? query}) {
    final path = query != null && query.isNotEmpty
        ? '/api/community/blogs?query=${Uri.encodeComponent(query)}'
        : '/api/community/blogs';
    return _request('GET', path, token: token);
  }

  static Future<Map<String, dynamic>> toggleStoryLike(String token, String storyId) {
    return _request('POST', '/api/community/stories/$storyId/like', token: token);
  }

  static Future<Map<String, dynamic>> createCommunityStory(
    String token,
    String title,
    String content,
    bool isAnonymous,
  ) {
    return _request('POST', '/api/community/stories', token: token, body: {
      'title': title,
      'snippet': content,
      'anonymous': isAnonymous,
    });
  }

  // --- SOS & Emergency Contacts ---
  static Future<Map<String, dynamic>> addEmergencyContact(
    String token,
    String name,
    String phone,
  ) {
    return _request('POST', '/api/users/contacts', token: token, body: {
      'name': name,
      'phone': phone,
    });
  }

  static Future<Map<String, dynamic>> removeEmergencyContact(
    String token,
    String contactId,
  ) {
    return _request('DELETE', '/api/users/contacts/$contactId', token: token);
  }

  static Future<Map<String, dynamic>> getUserById(String token, String userId) {
    return _request('GET', '/api/users/$userId', token: token);
  }

  static Future<Map<String, dynamic>> getFollowInfo(String token, String targetId) {
    return _request('GET', '/api/users/follow/info/$targetId', token: token);
  }

  static Future<Map<String, dynamic>> followVolunteer(
    String token,
    String targetId,
  ) {
    return _request('POST', '/api/users/follow/$targetId', token: token);
  }

  static Future<Map<String, dynamic>> getVolunteerWork(String token, String volunteerId) {
    return _request('GET', '/api/help-requests/volunteer/$volunteerId', token: token);
  }

  static Future<Map<String, dynamic>> getFollowRequests(String token) {
    return _request('GET', '/api/users/follow/requests', token: token);
  }

  static Future<Map<String, dynamic>> respondToFollowRequest(String token, String requesterId, String action) {
    return _request('POST', '/api/users/follow/respond', token: token, body: {
      'requesterId': requesterId,
      'action': action,
    });
  }
}