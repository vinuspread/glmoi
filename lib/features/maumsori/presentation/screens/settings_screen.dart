import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/maumsori_sidebar.dart';
import '../providers/config_provider.dart';
import '../../data/models/config_model.dart';
import 'settings/widgets/content_settings_tab.dart';
import 'settings/widgets/settings_header.dart';
import 'settings/widgets/settings_tab_bar.dart';
import 'settings/widgets/terms_tab.dart';
import 'settings/widgets/version_mode_tab.dart';
import 'package:app_admin/core/widgets/admin_background.dart';
import 'package:app_admin/core/firebase/firebase_env_options.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // App Config Controllers
  final _minVersionController = TextEditingController();
  final _latestVersionController = TextEditingController();
  final _maintenanceMsgController = TextEditingController();
  bool _isMaintenance = false;

  // Terms Config Controllers
  final _termsController = TextEditingController();
  final _privacyController = TextEditingController();

  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isSyncingToProd = false;

  // Composer defaults
  int _composerFontSize = 24;
  double _composerLineHeight = 1.6;
  double _composerDimStrength = 0.4;
  String _composerFontStyle = 'gothic';

  // Categories
  List<String> _categories = const [];
  final _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _minVersionController.dispose();
    _latestVersionController.dispose();
    _maintenanceMsgController.dispose();
    _termsController.dispose();
    _privacyController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch Configs
    final appConfigAsync = ref.watch(appConfigProvider);
    final termsConfigAsync = ref.watch(termsConfigProvider);

    final projectId = Firebase.app().options.projectId;
    final showSyncToProd = projectId == 'glmoi-dev';

    // Initialize values once when data is loaded
    if (!_isInitialized &&
        appConfigAsync.hasValue &&
        termsConfigAsync.hasValue) {
      final appConfig = appConfigAsync.value!;
      final termsConfig = termsConfigAsync.value!;

      _minVersionController.text = appConfig.minVersion;
      _latestVersionController.text = appConfig.latestVersion;
      _maintenanceMsgController.text = appConfig.maintenanceMessage;
      _isMaintenance = appConfig.isMaintenanceMode;

      _composerFontSize = appConfig.composerFontSize;
      _composerLineHeight = appConfig.composerLineHeight;
      _composerDimStrength = appConfig.composerDimStrength;
      _composerFontStyle = appConfig.composerFontStyle;

      _categories = List<String>.from(appConfig.categories);

      _termsController.text = termsConfig.termsOfService;
      _privacyController.text = termsConfig.privacyPolicy;

      _isInitialized = true;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/settings'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Column(
                children: [
                  const SettingsHeader(),
                  SettingsTabBar(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ContentSettingsTab(
                          composerFontSize: _composerFontSize,
                          onComposerFontSizeChanged: (v) =>
                              setState(() => _composerFontSize = v),
                          composerLineHeight: _composerLineHeight,
                          onComposerLineHeightChanged: (v) =>
                              setState(() => _composerLineHeight = v),
                          composerDimStrength: _composerDimStrength,
                          onComposerDimStrengthChanged: (v) =>
                              setState(() => _composerDimStrength = v),
                          composerFontStyle: _composerFontStyle,
                          onComposerFontStyleChanged: (v) =>
                              setState(() => _composerFontStyle = v),
                          categories: _categories,
                          newCategoryController: _newCategoryController,
                          onAddCategory: _addCategory,
                          onEditCategory: _editCategory,
                          onDeleteCategory: (value) =>
                              () => _deleteCategory(value),
                          isSaving: _isSaving,
                          onSave: _saveAppConfig,
                          showSyncToProd: showSyncToProd,
                          isSyncingToProd: _isSyncingToProd,
                          onSyncToProd: _syncSettingsToProd,
                        ),
                        VersionModeTab(
                          minVersionController: _minVersionController,
                          latestVersionController: _latestVersionController,
                          maintenanceMsgController: _maintenanceMsgController,
                          isMaintenance: _isMaintenance,
                          onMaintenanceChanged: (v) =>
                              setState(() => _isMaintenance = v),
                          isSaving: _isSaving,
                          onSave: _saveAppConfig,
                        ),
                        TermsTab(
                          termsController: _termsController,
                          privacyController: _privacyController,
                          isSaving: _isSaving,
                          onSave: _saveTermsConfig,
                        ),
                      ],
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

  Future<void> _syncSettingsToProd() async {
    final currentProjectId = Firebase.app().options.projectId;
    if (currentProjectId != 'glmoi-dev') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DEV 환경에서만 사용 가능합니다. (current: $currentProjectId)'),
        ),
      );
      return;
    }

    final defaultEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final emailController = TextEditingController(text: defaultEmail);
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('PROD로 설정값 반영'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '아래 설정 문서를 DEV에서 PROD로 복사합니다.\n'
                  '- config/app_config\n'
                  '- config/ad_config\n'
                  '- config/terms_config\n'
                  '- admin_settings/bad_words\n\n'
                  '이미지/콘텐츠는 포함되지 않습니다.\n'
                  '안전을 위해 매번 PROD 비밀번호를 입력합니다.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'PROD admin email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PROD admin password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('반영'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일/비밀번호를 입력해주세요.')));
      return;
    }

    setState(() => _isSyncingToProd = true);
    try {
      FirebaseApp prodApp;
      try {
        prodApp = Firebase.app('prod');
      } catch (_) {
        prodApp = await Firebase.initializeApp(
          name: 'prod',
          options: FirebaseEnvOptions.prod,
        );
      }

      final prodAuth = FirebaseAuth.instanceFor(app: prodApp);
      await prodAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final devFs = FirebaseFirestore.instance;
      final prodFs = FirebaseFirestore.instanceFor(app: prodApp);

      final toCopy = <({String collection, String doc})>[
        (collection: 'config', doc: 'app_config'),
        (collection: 'config', doc: 'ad_config'),
        (collection: 'config', doc: 'terms_config'),
        (collection: 'admin_settings', doc: 'bad_words'),
      ];

      final copied = <String>[];
      final skipped = <String>[];

      for (final item in toCopy) {
        final devRef = devFs.collection(item.collection).doc(item.doc);
        final snap = await devRef.get();
        final data = snap.data();
        final path = '${item.collection}/${item.doc}';
        if (data == null) {
          skipped.add(path);
          continue;
        }

        final prodRef = prodFs.collection(item.collection).doc(item.doc);
        await prodRef.set(data);
        copied.add(path);
      }

      await prodAuth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PROD 반영 완료. copied=${copied.length}, skipped=${skipped.length}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PROD 반영 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSyncingToProd = false);
    }
  }

  Future<void> _saveAppConfig() async {
    setState(() => _isSaving = true);
    try {
      final config = AppConfigModel(
        minVersion: _minVersionController.text,
        latestVersion: _latestVersionController.text,
        isMaintenanceMode: _isMaintenance,
        maintenanceMessage: _maintenanceMsgController.text,

        composerFontSize: _composerFontSize,
        composerLineHeight: _composerLineHeight,
        composerDimStrength: _composerDimStrength,
        composerFontStyle: _composerFontStyle,

        categories: _categories,
      );
      await ref.read(configControllerProvider).updateAppConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('앱 설정이 저장되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveTermsConfig() async {
    setState(() => _isSaving = true);
    try {
      final config = TermsConfigModel(
        termsOfService: _termsController.text,
        privacyPolicy: _privacyController.text,
      );
      await ref.read(configControllerProvider).updateTermsConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('약관이 저장되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addCategory() {
    final raw = _newCategoryController.text.trim();
    if (raw.isEmpty) return;
    if (_categories.contains(raw)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 존재하는 카테고리입니다.')));
      return;
    }
    setState(() {
      _categories = [..._categories, raw];
      _newCategoryController.clear();
    });
  }

  Future<void> _editCategory(String oldValue) async {
    final controller = TextEditingController(text: oldValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    final trimmed = (newValue ?? '').trim();
    if (trimmed.isEmpty) return;
    if (trimmed != oldValue && _categories.contains(trimmed)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 존재하는 카테고리입니다.')));
      return;
    }

    setState(() {
      _categories = _categories
          .map((c) => c == oldValue ? trimmed : c)
          .toList();
    });
  }

  void _deleteCategory(String value) {
    setState(() {
      _categories = _categories.where((c) => c != value).toList();
    });
  }
}
