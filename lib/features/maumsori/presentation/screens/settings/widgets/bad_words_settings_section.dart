import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:app_admin/core/theme/app_theme.dart';
import '../../../providers/bad_words_provider.dart';
import '../../../../data/models/bad_words_model.dart';
import '../../maumsori_dashboard/widgets/permission_denied_card.dart';

class BadWordsSettingsSection extends ConsumerStatefulWidget {
  const BadWordsSettingsSection({super.key});

  @override
  ConsumerState<BadWordsSettingsSection> createState() =>
      _BadWordsSettingsSectionState();
}

class _BadWordsSettingsSectionState
    extends ConsumerState<BadWordsSettingsSection> {
  final _plainController = TextEditingController();
  final _regexController = TextEditingController();
  String? _regexError;
  bool _didInit = false;

  @override
  void dispose() {
    _plainController.dispose();
    _regexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_didInit) {
      _didInit = true;
      Future.microtask(() async {
        try {
          await ref.read(badWordsControllerProvider).ensureInitialized();
        } catch (_) {
          // If Rules deny access, the StreamProvider below will surface it.
        }
      });
    }

    final configAsync = ref.watch(badWordsConfigProvider);
    final controller = ref.read(badWordsControllerProvider);

    final permissionDenied = () {
      if (!configAsync.hasError) return false;
      final err = configAsync.error;
      if (err is FirebaseException) {
        return err.code == 'permission-denied';
      }
      final s = err.toString();
      return s.contains('permission-denied') ||
          s.contains('Missing or insufficient permissions');
    }();

    final config = configAsync.valueOrNull ?? BadWordsConfig.empty();
    final rules = config.sortedRules();
    final plainRules = rules
        .where((r) => r.mode == BadWordRuleMode.plain)
        .toList();
    final regexRules = rules
        .where((r) => r.mode == BadWordRuleMode.regex)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '금지어 규칙 (글모이)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '변칙 단어(예: 씨.발, 씨~발, 씨1발)는 공백/특수문자/숫자를 제거한 텍스트로도 검사합니다.\n'
          'Regex 규칙은 고급 옵션이며, 잘못된 패턴은 무시될 수 있습니다.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        if (permissionDenied)
          PermissionDeniedCard(
            userEmail: FirebaseAuth.instance.currentUser?.email ?? '(unknown)',
            projectId: Firebase.app().options.projectId,
            resource: 'admin_settings/bad_words',
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) Plain input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _plainController,
                        decoration: const InputDecoration(
                          labelText: '금지어 추가 (텍스트)',
                          hintText: '예: 씨발, 주식 리딩방, 010',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addPlain(controller),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _addPlain(controller),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('추가'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2) Plain rules list
                _RulesSection(
                  title: '텍스트 규칙',
                  isLoading: configAsync.isLoading,
                  error: configAsync.hasError
                      ? configAsync.error.toString()
                      : null,
                  rules: plainRules,
                  onDelete: (id) => controller.deleteRule(id),
                  compact: true,
                ),
                const SizedBox(height: 24),

                // 3) Regex input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _regexController,
                        decoration: InputDecoration(
                          labelText: 'Regex 규칙 추가 (고급)',
                          hintText:
                              r'예: (0?1[016789])[- .]?[0-9]{3,4}[- .]?[0-9]{4}',
                          border: const OutlineInputBorder(),
                          errorText: _regexError,
                        ),
                        onChanged: (_) => _validateRegex(),
                        onSubmitted: (_) => _addRegex(controller),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _regexError != null
                          ? null
                          : () => _addRegex(controller),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('추가'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4) Regex rules list
                _RulesSection(
                  title: 'Regex 규칙',
                  isLoading: configAsync.isLoading,
                  error: configAsync.hasError
                      ? configAsync.error.toString()
                      : null,
                  rules: regexRules,
                  onDelete: (id) => controller.deleteRule(id),
                  compact: true,
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _hasDuplicateRuleValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;

    final config = ref.read(badWordsConfigProvider).valueOrNull;
    if (config == null) return false;

    return config.rules.values.any((r) => r.value.trim() == value);
  }

  void _validateRegex() {
    final raw = _regexController.text.trim();
    if (raw.isEmpty) {
      if (_regexError != null) setState(() => _regexError = null);
      return;
    }
    try {
      RegExp(raw);
      if (_regexError != null) setState(() => _regexError = null);
    } catch (e) {
      setState(() => _regexError = '정규표현식이 올바르지 않습니다');
    }
  }

  Future<void> _addPlain(BadWordsController controller) async {
    final raw = _plainController.text.trim();
    if (raw.isEmpty) return;

    if (_hasDuplicateRuleValue(raw)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 존재하는 금지어입니다.')));
      return;
    }

    await controller.addPlainWord(raw);
    if (!mounted) return;
    _plainController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('금지어가 추가되었습니다.')));
  }

  Future<void> _addRegex(BadWordsController controller) async {
    _validateRegex();
    if (_regexError != null) return;

    final raw = _regexController.text.trim();
    if (raw.isEmpty) return;

    if (_hasDuplicateRuleValue(raw)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 존재하는 규칙입니다.')));
      return;
    }

    await controller.addRegex(raw);
    if (!mounted) return;
    _regexController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Regex 규칙이 추가되었습니다.')));
  }
}

class _RulesSection extends StatelessWidget {
  final String title;
  final bool isLoading;
  final String? error;
  final List<BadWordRule> rules;
  final Future<void> Function(String id) onDelete;
  final bool compact;

  const _RulesSection({
    required this.title,
    required this.isLoading,
    required this.error,
    required this.rules,
    required this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (error != null)
          Text('불러오기 실패: $error', style: const TextStyle(color: Colors.red))
        else if (isLoading && rules.isEmpty)
          const Text(
            '불러오는 중...',
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else if (rules.isEmpty)
          const Text(
            '등록된 규칙이 없습니다.',
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else
          Wrap(
            spacing: compact ? 12 : 8,
            runSpacing: compact ? 10 : 8,
            children: rules.map((r) {
              return _RuleTag(rule: r, onDelete: () => onDelete(r.id));
            }).toList(),
          ),
      ],
    );
  }
}

class _RuleTag extends StatelessWidget {
  final BadWordRule rule;
  final VoidCallback onDelete;

  const _RuleTag({required this.rule, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textColor = rule.isEnabled
        ? AppTheme.textPrimary
        : AppTheme.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rule.value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.close, size: 14),
          color: AppTheme.textSecondary,
          tooltip: '삭제',
          padding: const EdgeInsets.only(left: 6),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

// _RuleChip removed. We use compact text tags (+ X) for both plain and regex.
