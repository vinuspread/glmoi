import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:app_admin/core/widgets/admin_background.dart';
import '../widgets/maumsori_sidebar.dart';

class AutoSendScreen extends ConsumerStatefulWidget {
  const AutoSendScreen({super.key});

  @override
  ConsumerState<AutoSendScreen> createState() => _AutoSendScreenState();
}

class _AutoSendScreenState extends ConsumerState<AutoSendScreen> {
  bool _isEnabled = false;
  TimeOfDay _firstSendTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _secondSendTime;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('getAutoSendConfig').call();
      final data = result.data as Map<String, dynamic>;

      setState(() {
        _isEnabled = data['is_enabled'] ?? false;

        final firstTime = data['first_send_time'] as String?;
        if (firstTime != null) {
          final parts = firstTime.split(':');
          _firstSendTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        final secondTime = data['second_send_time'] as String?;
        if (secondTime != null) {
          final parts = secondTime.split(':');
          _secondSendTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 불러오기 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/auto-send'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEnableSection(),
                          const SizedBox(height: 24),
                          if (_isEnabled) ...[
                            _buildTimeSettingsSection(),
                            const SizedBox(height: 24),
                            _buildTestSendSection(),
                            const SizedBox(height: 24),
                            _buildInfoSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_isEnabled) _buildSaveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_send,
            size: 28,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 12),
          Text(
            '자동발송 관리',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnableSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '자동발송 활성화',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '설정한 시간에 자동으로 콘텐츠를 푸시 알림으로 발송합니다.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '발송 시간 설정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimeSelector(
            label: '1차 발송 시간 (필수)',
            time: _firstSendTime,
            onTap: () async {
              final time = await _selectTime(context, _firstSendTime);
              if (time != null) {
                setState(() {
                  _firstSendTime = time;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTimeSelector(
            label: '2차 발송 시간 (선택)',
            time: _secondSendTime,
            onTap: () async {
              final time = await _selectTime(context, _secondSendTime);
              setState(() {
                _secondSendTime = time;
              });
            },
            onClear: _secondSendTime != null
                ? () {
                    setState(() {
                      _secondSendTime = null;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        time != null
                            ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                            : '시간 선택',
                        style: TextStyle(
                          fontSize: 16,
                          color: time != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(width: 16),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            tooltip: '삭제',
          ),
        ],
      ],
    );
  }

  Widget _buildTestSendSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.send, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                '테스트 발송',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '지금 즉시 푸시 알림을 테스트로 발송합니다. 모든 사용자에게 전송됩니다.',
            style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSending ? null : _sendTestNotification,
            icon: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_isSending ? '발송 중...' : '지금 발송'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              minimumSize: const Size(150, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                '안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 하루 최대 2회까지 자동발송이 가능합니다.\n'
            '• 설정한 시간에 랜덤으로 선택된 콘텐츠가 푸시 알림으로 발송됩니다.\n'
            '• 푸시 알림을 받은 사용자는 바탕화면 위젯에서도 해당 콘텐츠를 볼 수 있습니다.\n'
            '• 발송 기록은 Firebase Functions 로그에서 확인할 수 있습니다.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade900,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () {},
            style: OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
            child: const Text('취소'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<TimeOfDay?> _selectTime(
    BuildContext context,
    TimeOfDay? initialTime,
  ) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isSending = true;
    });

    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('triggerAutoSendNow').call();
      final data = result.data as Map<String, dynamic>;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '푸시 알림이 발송되었습니다!\n'
            '콘텐츠: ${data['content_preview']}...',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('발송 실패: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final functions = FirebaseFunctions.instance;

      final firstTimeStr =
          '${_firstSendTime.hour.toString().padLeft(2, '0')}:${_firstSendTime.minute.toString().padLeft(2, '0')}';
      final secondTimeStr = _secondSendTime != null
          ? '${_secondSendTime!.hour.toString().padLeft(2, '0')}:${_secondSendTime!.minute.toString().padLeft(2, '0')}'
          : null;

      await functions.httpsCallable('saveAutoSendConfig').call({
        'is_enabled': _isEnabled,
        'first_send_time': firstTimeStr,
        'second_send_time': secondTimeStr,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자동발송 설정이 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
