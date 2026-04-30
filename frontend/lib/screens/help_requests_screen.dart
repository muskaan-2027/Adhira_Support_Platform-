import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/help_request_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'user_dashboard_screen.dart';
import 'volunteer_dashboard_screen.dart';

class HelpRequestsScreen extends StatefulWidget {
  final bool isVolunteer;
  final String? statusFilter;
  final String title;

  const HelpRequestsScreen({
    super.key,
    required this.isVolunteer,
    this.statusFilter,
    this.title = 'My Help Requests',
  });

  @override
  State<HelpRequestsScreen> createState() => _HelpRequestsScreenState();
}

class _HelpRequestsScreenState extends State<HelpRequestsScreen> {
  bool _loading = false;
  List<HelpRequestModel> _requests = [];
  final Map<String, TextEditingController> _followUpControllers = {};

  @override
  void dispose() {
    for (var controller in _followUpControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');

      final response = await ApiService.getHelpRequests(token);
      final list = response['requests'] as List<dynamic>? ?? [];
      var parsed = list
          .whereType<Map<String, dynamic>>()
          .map(HelpRequestModel.fromJson)
          .toList();

      if (widget.statusFilter != null && widget.statusFilter != 'all') {
        parsed = parsed.where((item) => item.status == widget.statusFilter).toList();
      }

      setState(() {
        _requests = parsed;
      });
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String requestId, String status) async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');

      String? assistanceNote;
      if (status == 'completed') {
        final noteController = TextEditingController();
        assistanceNote = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Assistance Note', style: TextStyle(fontWeight: FontWeight.bold)),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What help did you provide?',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context, noteController.text.trim()),
                child: const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (assistanceNote == null) return;
      }

      await ApiService.updateHelpRequestStatus(token, requestId, status, assistanceNote: assistanceNote);
      await _loadRequests();
      if (!mounted) return;
      NotificationService.showMessage(context, 'Status updated to $status');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _rateVolunteer(String requestId) async {
    int selectedRating = 5;
    final reviewController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Rate Assistance', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How helpful was this volunteer?'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedRating = index + 1),
                        child: Icon(
                          index < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: reviewController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Leave a comment',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context, {'rating': selectedRating, 'review': reviewController.text.trim()}),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      await ApiService.rateHelpRequest(token, requestId, result['rating'], result['review']);
      await _loadRequests();
      if (!mounted) return;
      NotificationService.showMessage(context, 'Thank you for your feedback!');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _sendFollowUp(String requestId, String message) async {
    if (message.isEmpty) return;

    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      await ApiService.addHelpRequestFollowUp(token, requestId, message);
      _followUpControllers[requestId]?.clear();
      await _loadRequests();
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    }
  }

  Map<String, dynamic> _getCategoryInfo(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('legal') || msg.contains('case') || msg.contains('law')) {
      return {'label': 'Legal Support', 'icon': Icons.gavel_rounded, 'color': Colors.deepPurple};
    }
    if (msg.contains('anxious') || msg.contains('mental') || msg.contains('talk') || msg.contains('feel') || msg.contains('stress')) {
      return {'label': 'Mental Health', 'icon': Icons.psychology_rounded, 'color': Colors.blue};
    }
    if (msg.contains('plan') || msg.contains('safe') || msg.contains('emergency')) {
      return {'label': 'Safety Planning', 'icon': Icons.shield_rounded, 'color': Colors.indigo};
    }
    if (msg.contains('financial') || msg.contains('money') || msg.contains('support') || msg.contains('fund')) {
      return {'label': 'Financial Help', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.green};
    }
    return {'label': 'General Advice', 'icon': Icons.chat_bubble_outline_rounded, 'color': Colors.orange};
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _requests.length;
    final inProgress = _requests.where((r) => r.status == 'accepted').length;
    final completed = _requests.where((r) => r.status == 'completed').length;
    final closed = _requests.where((r) => r.status == 'rejected').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (widget.isVolunteer) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => VolunteerDashboardScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => UserDashboardScreen()),
              );
            }
          },
        ),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(total, inProgress, completed, closed),
                Expanded(
                  child: _requests.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(int total, int inProgress, int completed, int closed) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Track your help requests and check status in real-time.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard('Total Requests', total, AppColors.primary, Icons.assignment_rounded),
                _buildStatCard('In Progress', inProgress, const Color(0xFF3B82F6), Icons.update_rounded),
                _buildStatCard('Completed', completed, const Color(0xFF10B981), Icons.verified_rounded),
                _buildStatCard('Closed', closed, const Color(0xFFF43F5E), Icons.cancel_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(count.toString(), style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(HelpRequestModel request) {
    final cat = _getCategoryInfo(request.message);
    final statusColor = _getStatusColor(request.status);
    final isCompleted = request.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (cat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.message,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      // Sender & Receiver Section
                      Row(
                        children: [
                          _buildNameBadge('From', request.requesterName, Colors.blue),
                          const SizedBox(width: 8),
                          _buildNameBadge('To', request.volunteerName ?? 'Any Volunteer', Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(color: cat['color'] as Color, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'REQ-${request.id.substring(request.id.length - 6).toUpperCase()}  •  ${_formatDate(request.createdAt)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _capitalize(request.status),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCompleted ? 'Completed' : 'Updated',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatDate(request.createdAt),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (request.assistanceNote.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded, color: Color(0xFF166534), size: 18),
                      SizedBox(width: 8),
                      Text('Advice from Volunteer', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.assistanceNote,
                    style: const TextStyle(color: Color(0xFF14532D), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          if (request.followUps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Conversation History', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 12),
                  ...request.followUps.map((f) => _buildFollowUpItem(f)),
                ],
              ),
            ),
          const Divider(height: 32, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Volunteer Rating', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    if (request.rating > 0)
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < request.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 18,
                        )),
                      )
                    else
                      const Text('No rating given', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
                if (widget.isVolunteer)
                  Row(
                    children: [
                      if (request.status == 'pending')
                        _buildSmallButton('Accept', AppColors.primary, true, () => _updateStatus(request.id, 'accepted')),
                      if (request.status == 'pending')
                        const SizedBox(width: 8),
                      if (request.status == 'pending')
                        _buildSmallButton('Reject', Colors.red, false, () => _updateStatus(request.id, 'rejected')),
                      if (request.status == 'accepted')
                        _buildSmallButton('Mark Complete', AppColors.primary, true, () => _updateStatus(request.id, 'completed')),
                    ],
                  )
                else if (isCompleted && request.rating == 0)
                  _buildSmallButton('Rate Experience', AppColors.primary, true, () => _rateVolunteer(request.id)),
              ],
            ),
          ),
          if (request.status == 'accepted' || request.status == 'completed')
            _buildFollowUpInput(request.id),
        ],
      ),
    );
  }

  Widget _buildFollowUpInput(String requestId) {
    if (!_followUpControllers.containsKey(requestId)) {
      _followUpControllers[requestId] = TextEditingController();
    }
    final controller = _followUpControllers[requestId]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ask a follow-up question', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type your question here...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.softPurple, width: 1.5),
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _sendFollowUp(requestId, controller.text.trim()),
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  tooltip: 'Send Question',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpItem(FollowUpModel followUp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(followUp.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
              Text(_formatDate(followUp.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(followUp.message, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildNameBadge(String label, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(String label, Color color, bool filled, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? color : Colors.white,
        foregroundColor: filled ? Colors.white : color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: filled ? BorderSide.none : BorderSide(color: color),
        ),
        minimumSize: const Size(0, 36),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.softPurple, shape: BoxShape.circle),
            child: const Icon(Icons.assignment_late_rounded, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text('No help requests yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('You will see your requests here.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return const Color(0xFF10B981);
      case 'accepted': return const Color(0xFF3B82F6);
      case 'rejected': return const Color(0xFFF43F5E);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _capitalize(String s) => s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';
}
