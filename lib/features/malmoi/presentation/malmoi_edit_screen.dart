import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/login_redirect.dart';
import '../../quotes/data/quotes_repository.dart';
import '../../quotes/domain/quote.dart';

final _quotesRepoProvider = Provider((ref) => QuotesRepository());

class MalmoiEditScreen extends ConsumerStatefulWidget {
  final Quote quote;
  const MalmoiEditScreen({super.key, required this.quote});

  @override
  ConsumerState<MalmoiEditScreen> createState() => _MalmoiEditScreenState();
}

class _MalmoiEditScreenState extends ConsumerState<MalmoiEditScreen> {
  late final TextEditingController _controller;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quote.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(_quotesRepoProvider).updateMalmoiPost(
            quoteId: widget.quote.id,
            content: content,
          );
      if (!mounted) return;
      context.pop(content);
    } catch (e) {
      if (!mounted) return;
      final msg = (e is FirebaseFunctionsException)
          ? (e.code == 'failed-precondition'
              ? '사용할 수 없는 단어가 있습니다.'
              : (e.code == 'unauthenticated' ? '로그인이 필요합니다.' : '저장에 실패했습니다.'))
          : '저장에 실패했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        context.push('/login', extra: const LoginRedirect.pop());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 수정'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radius16),
                border: Border.all(color: AppTheme.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.edit_note,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '내용만 수정할 수 있어요.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                maxLength: 2000,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요 (최대 2,000자)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}
