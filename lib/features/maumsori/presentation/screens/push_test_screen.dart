import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:app_admin/core/widgets/admin_background.dart';
import '../widgets/maumsori_sidebar.dart';

class PushTestScreen extends StatefulWidget {
  const PushTestScreen({super.key});

  @override
  State<PushTestScreen> createState() => _PushTestScreenState();
}

class _PushTestScreenState extends State<PushTestScreen> {
  List<_FcmUser> _users = [];
  _FcmUser? _selectedUser;
  bool _loadingUsers = true;
  String? _lastResult;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('fcm_token', isNull: false)
          .limit(100)
          .get();
      setState(() {
        _users = snap.docs
            .map(
              (d) => _FcmUser(
                uid: d.id,
                displayName:
                    (d.data()['display_name'] as String?)?.trim() ?? '',
                fcmToken: d.data()['fcm_token'] as String,
              ),
            )
            .where((u) => u.fcmToken.isNotEmpty)
            .toList();
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _sendTest(String scenario) async {
    if (_selectedUser == null) {
      setState(() => _lastResult = '먼저 대상 사용자를 선택하세요.');
      return;
    }
    setState(() {
      _sending = true;
      _lastResult = null;
    });
    try {
      await FirebaseFunctions.instanceFor(region: 'asia-northeast3')
          .httpsCallable('sendTestNotification')
          .call({'targetUid': _selectedUser!.uid, 'scenario': scenario});
      setState(() => _lastResult = '✓ 발송 완료 ($scenario)');
    } on FirebaseFunctionsException catch (e) {
      setState(() => _lastResult = '✗ 실패: ${e.message}');
    } catch (e) {
      setState(() => _lastResult = '✗ 오류: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/push-test'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserPicker(),
                            const SizedBox(height: 32),
                            _buildScenarioSection('인터랙션', [
                              _ScenarioDef(
                                'like',
                                '좋아요',
                                Icons.favorite_outline,
                                const Color(0xFFEF4444),
                              ),
                              _ScenarioDef(
                                'share',
                                '공유',
                                Icons.share_outlined,
                                const Color(0xFF3B82F6),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            _buildScenarioSection('반응', [
                              _ScenarioDef(
                                'react_comfort',
                                '위로받았어요',
                                Icons.sentiment_satisfied_alt_outlined,
                                const Color(0xFF8B5CF6),
                              ),
                              _ScenarioDef(
                                'react_empathize',
                                '공감해요',
                                Icons.handshake_outlined,
                                const Color(0xFF0EA5E9),
                              ),
                              _ScenarioDef(
                                'react_good',
                                '좋아요 (반응)',
                                Icons.thumb_up_outlined,
                                const Color(0xFF10B981),
                              ),
                              _ScenarioDef(
                                'react_touched',
                                '감동받았어요',
                                Icons.auto_awesome_outlined,
                                const Color(0xFFF59E0B),
                              ),
                              _ScenarioDef(
                                'react_fan',
                                '팬이에요',
                                Icons.star_outline,
                                const Color(0xFFEC4899),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            _buildScenarioSection('조회수 마일스톤', [
                              _ScenarioDef(
                                'view_3',
                                '3명',
                                Icons.visibility_outlined,
                                AppTheme.textSecondary,
                              ),
                              _ScenarioDef(
                                'view_50',
                                '50명',
                                Icons.visibility_outlined,
                                AppTheme.textSecondary,
                              ),
                              _ScenarioDef(
                                'view_100',
                                '100명',
                                Icons.visibility_outlined,
                                AppTheme.textSecondary,
                              ),
                              _ScenarioDef(
                                'view_300',
                                '300명',
                                Icons.visibility_outlined,
                                AppTheme.textSecondary,
                              ),
                              _ScenarioDef(
                                'view_500',
                                '500명',
                                Icons.visibility_outlined,
                                AppTheme.textSecondary,
                              ),
                              _ScenarioDef(
                                'view_800',
                                '800명',
                                Icons.visibility_outlined,
                                AppTheme.textSecondary,
                              ),
                              _ScenarioDef(
                                'view_1000',
                                '1000명',
                                Icons.visibility_outlined,
                                AppTheme.textSecondary,
                              ),
                            ]),
                            if (_lastResult != null) ...[
                              const SizedBox(height: 24),
                              _buildResultBanner(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Text(
            '푸시 알림 테스트',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('새로고침'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '대상 사용자',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'FCM 토큰이 등록된 사용자만 표시됩니다. 앱에 로그인해야 토큰이 저장됩니다.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        if (_loadingUsers)
          const CircularProgressIndicator()
        else if (_users.isEmpty)
          const Text(
            'FCM 토큰이 등록된 사용자가 없습니다.',
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_FcmUser>(
                value: _selectedUser,
                isExpanded: true,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('사용자 선택'),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: _users.map((u) {
                  final label = u.displayName.isNotEmpty
                      ? u.displayName
                      : u.uid;
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      '$label  •  ${u.uid}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedUser = v),
              ),
            ),
          ),
        if (_selectedUser != null) ...[
          const SizedBox(height: 8),
          SelectableText(
            'UID: ${_selectedUser!.uid}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildScenarioSection(String title, List<_ScenarioDef> scenarios) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scenarios
              .map(
                (s) => _ScenarioChip(
                  def: s,
                  sending: _sending,
                  onTap: () => _sendTest(s.scenario),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResultBanner() {
    final isSuccess = _lastResult!.startsWith('✓');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isSuccess ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Text(
        _lastResult!,
        style: TextStyle(
          color: isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ScenarioChip extends StatelessWidget {
  final _ScenarioDef def;
  final bool sending;
  final VoidCallback onTap;

  const _ScenarioChip({
    required this.def,
    required this.sending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: sending ? null : onTap,
      icon: Icon(def.icon, size: 16, color: def.color),
      label: Text(def.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _ScenarioDef {
  final String scenario;
  final String label;
  final IconData icon;
  final Color color;

  const _ScenarioDef(this.scenario, this.label, this.icon, this.color);
}

class _FcmUser {
  final String uid;
  final String displayName;
  final String fcmToken;

  const _FcmUser({
    required this.uid,
    required this.displayName,
    required this.fcmToken,
  });

  @override
  bool operator ==(Object other) => other is _FcmUser && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}
