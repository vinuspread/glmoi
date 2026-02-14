import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:app_admin/core/theme/app_theme.dart';
import 'package:app_admin/core/widgets/admin_background.dart';
import '../../data/repositories/member_repository.dart';
import '../providers/member_provider.dart';
import '../widgets/maumsori_sidebar.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() =>
      _MemberManagementScreenState();
}

class _MemberManagementScreenState
    extends ConsumerState<MemberManagementScreen> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSuspendDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic member,
  ) async {
    final isSuspended = member.isSuspended as bool;
    final action = isSuspended ? '정지 해제' : '정지';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회원 $action'),
        content: Text(
          isSuspended
              ? '${member.displayName} 님의 정지를 해제하시겠습니까?'
              : '${member.displayName} 님을 정지하시겠습니까?\n\n정지된 회원은 앱 사용이 제한됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              action,
              style: TextStyle(
                color: isSuspended ? AppTheme.primaryPurple : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(memberRepositoryProvider);
        if (isSuspended) {
          await repo.unsuspendMember(member.uid);
        } else {
          await repo.suspendMember(member.uid);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$action 완료')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$action 실패: $e')));
        }
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 삭제'),
        content: Text(
          '${member.displayName} 님을 삭제하시겠습니까?\n\n⚠️ 이 작업은 되돌릴 수 없습니다.\n회원의 모든 데이터가 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(memberRepositoryProvider);
        await repo.deleteMember(member.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('삭제 완료')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final dateFmt = DateFormat('yyyy-MM-dd');
    final dateTimeFmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/members'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '회원 관리',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _query = v.trim()),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: '검색: 닉네임/이메일/UID/Provider',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: membersAsync.when(
                        data: (members) {
                          final q = _query.toLowerCase();
                          final filtered = q.isEmpty
                              ? members
                              : members.where((m) {
                                  final name = m.displayName.toLowerCase();
                                  final email = m.email.toLowerCase();
                                  final uid = m.uid.toLowerCase();
                                  final provider = m.provider.toLowerCase();
                                  final providerUserId = m.providerUserId
                                      .toLowerCase();
                                  return name.contains(q) ||
                                      email.contains(q) ||
                                      uid.contains(q) ||
                                      provider.contains(q) ||
                                      providerUserId.contains(q);
                                }).toList();

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '총 ${members.length}명',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (q.isNotEmpty)
                                        Text(
                                          '(검색 결과 ${filtered.length}명)',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    10,
                                  ),
                                  child: Row(
                                    children: const [
                                      SizedBox(width: 36),
                                      SizedBox(width: 14),
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          '닉네임',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 260,
                                        child: Text(
                                          '이메일',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Provider',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 160,
                                        child: Text(
                                          '최근 로그인',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          '가입일자',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'UID',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 1260,
                                      ),
                                      child: ListView.separated(
                                        itemCount: filtered.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, i) {
                                          final m = filtered[i];
                                          final name = m.displayName.isEmpty
                                              ? '-'
                                              : m.displayName;
                                          final email = m.email.isEmpty
                                              ? '-'
                                              : m.email;
                                          final provider = m.provider.isEmpty
                                              ? '-'
                                              : m.provider;
                                          final lastLogin =
                                              m.lastLoginAt == null
                                              ? '-'
                                              : dateTimeFmt.format(
                                                  m.lastLoginAt!,
                                                );
                                          final created = m.createdAt == null
                                              ? '-'
                                              : dateFmt.format(m.createdAt!);

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor:
                                                      AppTheme.accentLight,
                                                  backgroundImage:
                                                      m.photoUrl.isNotEmpty
                                                      ? NetworkImage(m.photoUrl)
                                                      : null,
                                                  child: m.photoUrl.isEmpty
                                                      ? const Icon(
                                                          Icons.person,
                                                          size: 18,
                                                          color: AppTheme
                                                              .primaryPurple,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 14),
                                                SizedBox(
                                                  width: 180,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                      if (m.isSuspended)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.only(
                                                                left: 6,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .red
                                                                .shade100,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '정지',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .red
                                                                  .shade700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 260,
                                                  child: Text(
                                                    email,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    provider,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 160,
                                                  child: Text(
                                                    lastLogin,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 130,
                                                  child: Text(created),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    m.uid,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                IconButton(
                                                  icon: Icon(
                                                    m.isSuspended
                                                        ? Icons.lock_open
                                                        : Icons.lock,
                                                    size: 18,
                                                  ),
                                                  tooltip: m.isSuspended
                                                      ? '정지 해제'
                                                      : '정지',
                                                  onPressed: () =>
                                                      _showSuspendDialog(
                                                        context,
                                                        ref,
                                                        m,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                  ),
                                                  tooltip: '삭제',
                                                  onPressed: () =>
                                                      _showDeleteDialog(
                                                        context,
                                                        ref,
                                                        m,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
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
}
