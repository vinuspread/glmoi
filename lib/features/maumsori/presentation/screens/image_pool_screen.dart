import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_dropzone_platform_interface/flutter_dropzone_platform_interface.dart';
import 'package:mime/mime.dart';
import '../widgets/maumsori_sidebar.dart';
import '../providers/image_provider.dart';
import '../providers/quote_provider.dart';
import 'image_pool/widgets/image_dropzone_panel.dart';
import 'image_pool/widgets/image_grid_item.dart';
import 'image_pool/widgets/image_options_dialog.dart';
import 'image_pool/widgets/image_pool_header.dart';
import 'package:app_admin/core/widgets/admin_background.dart';

class ImagePoolScreen extends ConsumerStatefulWidget {
  const ImagePoolScreen({super.key});

  @override
  ConsumerState<ImagePoolScreen> createState() => _ImagePoolScreenState();
}

class _ImagePoolScreenState extends ConsumerState<ImagePoolScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isBulkDeleting = false;
  final Set<String> _selectedImageIds = <String>{};

  DropzoneViewController? _dropzone;
  bool _isDragging = false;
  int _bulkTotal = 0;
  int _bulkDone = 0;
  String? _dropzoneError;

  String? _inferContentTypeFromName(String name) {
    final ct = lookupMimeType(name)?.toLowerCase();
    if (ct == null) return null;
    if (!ct.startsWith('image/')) return null;
    return ct;
  }

  bool _isSupportedImageContentType(String contentType) {
    final ct = contentType.toLowerCase();
    if (!ct.startsWith('image/')) return false;

    // Common formats that typically fail to preview on the web.
    // Keep these blocked to avoid "upload succeeded but preview always fails" confusion.
    if (ct == 'image/heic' || ct == 'image/heif') return false;

    return true;
  }

  String? _inferContentTypeFromDownloadUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isEmpty) return null;
      final encodedObjectPath = uri.pathSegments.last;
      final objectPath = Uri.decodeComponent(encodedObjectPath);
      final dot = objectPath.lastIndexOf('.');
      if (dot < 0 || dot == objectPath.length - 1) return null;
      final ext = objectPath.substring(dot + 1).toLowerCase();
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'webp':
          return 'image/webp';
        case 'gif':
          return 'image/gif';
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageListAsync = ref.watch(imageListProvider);
    final quotesAsync = ref.watch(quoteListProvider(null));

    final quoteImageUrlCounts = <String, int>{};
    final quotes = quotesAsync.value;
    if (quotes != null) {
      for (final q in quotes) {
        final url = q.imageUrl;
        if (url == null || url.isEmpty) continue;
        quoteImageUrlCounts.update(url, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/images'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Column(
                children: [
                  const ImagePoolHeader(),
                  _buildDropzonePanel(),
                  _buildSelectionBar(imageListAsync.value ?? const []),
                  Expanded(
                    child: imageListAsync.when(
                      data: (images) {
                        if (images.isEmpty) {
                          return const Center(child: Text('등록된 이미지가 없습니다.'));
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 80,
                                childAspectRatio: 9 / 16,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final image = images[index];
                            final previewUrl = image.thumbnailUrl.isNotEmpty
                                ? image.thumbnailUrl
                                : image.originalUrl;

                            var derivedUsageCount = image.usageCount;
                            if (quotes != null) {
                              final keys = <String>{
                                image.originalUrl,
                                image.thumbnailUrl,
                                if (image.webpUrl != null) image.webpUrl!,
                              };
                              derivedUsageCount = keys
                                  .where((k) => k.isNotEmpty)
                                  .map((k) => quoteImageUrlCounts[k] ?? 0)
                                  .fold(0, (a, b) => a + b);
                            }
                            return ImageGridItem(
                              previewUrl: previewUrl,
                              usageCount: derivedUsageCount,
                              isSelected: _selectedImageIds.contains(image.id),
                              onSelectedChanged: (v) {
                                final next = v ?? false;
                                setState(() {
                                  if (next) {
                                    _selectedImageIds.add(image.id);
                                  } else {
                                    _selectedImageIds.remove(image.id);
                                  }
                                });
                              },
                              onTap: () => _showImageOptions(
                                context,
                                image.id,
                                image.originalUrl,
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        backgroundColor: AppTheme.primaryPurple,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload),
        label: Text(_isUploading ? '업로드 중...' : '이미지 업로드'),
      ),
    );
  }

  Widget _buildSelectionBar(List<dynamic> images) {
    // Keep selection consistent with current list
    final existingIds = images.map((e) => (e as dynamic).id as String).toSet();
    final effectiveSelected = _selectedImageIds.intersection(existingIds);
    if (effectiveSelected.length != _selectedImageIds.length) {
      // Drop stale ids without triggering setState loops in build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedImageIds
            ..clear()
            ..addAll(effectiveSelected);
        });
      });
    }

    if (effectiveSelected.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text(
            '선택 ${effectiveSelected.length}개',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: _isBulkDeleting
                ? null
                : () => setState(() => _selectedImageIds.clear()),
            child: const Text('선택 해제'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _isBulkDeleting
                ? null
                : () async {
                    await _deleteSelectedImages();
                  },
            icon: _isBulkDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: const Text('선택 삭제'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedImages() async {
    final images = ref.read(imageListProvider).valueOrNull;
    if (images == null || images.isEmpty) return;

    final targets = images.where((img) => _selectedImageIds.contains(img.id));
    if (targets.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택 삭제'),
        content: Text('${targets.length}개의 이미지를 삭제합니다. 계속할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBulkDeleting = true);
    try {
      final controller = ref.read(imageControllerProvider);
      for (final img in targets) {
        await controller.deleteImage(
          img.id,
          originalUrl: img.originalUrl,
          thumbnailUrl: img.thumbnailUrl,
          webpUrl: img.webpUrl,
        );
      }

      if (!mounted) return;
      setState(() => _selectedImageIds.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택한 이미지가 삭제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    } finally {
      if (mounted) setState(() => _isBulkDeleting = false);
    }
  }

  Widget _buildDropzonePanel() {
    final isWeb = kIsWeb;
    final platformImpl = FlutterDropzonePlatform.instance.runtimeType
        .toString();
    // flutter_dropzone is web-only; if the web implementation isn't registered
    // (stale build cache, plugin registration issues), it falls back to a
    // MethodChannel implementation which isn't supported on desktop.
    // We hide the DropzoneView in that case to avoid rendering the macOS warning.
    final isDropzoneRegistered =
        isWeb && platformImpl != 'MethodChannelFlutterDropzone';

    final dropzoneView = isDropzoneRegistered
        ? DropzoneView(
            operation: DragOperation.copy,
            onCreated: (ctrl) => _dropzone = ctrl,
            onLoaded: () {
              if (_dropzoneError != null) {
                setState(() => _dropzoneError = null);
              }
            },
            onError: (msg) {
              setState(() => _dropzoneError = msg ?? 'unknown error');
            },
            onHover: () {
              if (!_isDragging) setState(() => _isDragging = true);
            },
            onLeave: () {
              if (_isDragging) setState(() => _isDragging = false);
            },
            onDropMultiple: (events) =>
                _uploadDroppedFiles(events ?? <dynamic>[]),
            onDrop: (event) => _uploadDroppedFiles([event]),
          )
        : null;

    return ImageDropzonePanel(
      isDragging: _isDragging,
      isUploading: _isUploading,
      bulkTotal: _bulkTotal,
      bulkDone: _bulkDone,
      isDropzoneRegistered: isDropzoneRegistered,
      dropzoneError: _dropzoneError,
      dropzoneView: dropzoneView,
      onPickMultiple: _pickAndUploadMultiple,
    );
  }

  Future<void> _pickAndUploadMultiple() async {
    try {
      // Use image_picker for multi-select across platforms.
      final files = await _picker.pickMultiImage();
      if (files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _isDragging = false;
        _bulkTotal = files.length;
        _bulkDone = 0;
      });

      int success = 0;
      int failed = 0;
      String? firstError;
      for (final file in files) {
        try {
          final bytes = await file.readAsBytes();
          final contentType =
              _inferContentTypeFromName(file.name) ??
              'application/octet-stream';

          if (!_isSupportedImageContentType(contentType)) {
            failed++;
            firstError ??= '지원하지 않는 이미지 형식: $contentType (${file.name})';
          } else {
            await ref
                .read(imageControllerProvider)
                .uploadImage(
                  fileName: file.name,
                  fileBytes: bytes,
                  mimeType: contentType,
                );
            success++;
          }
        } catch (e) {
          failed++;
          firstError ??= '$e';
        } finally {
          if (mounted) setState(() => _bulkDone++);
        }
      }

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firstError == null
                  ? '업로드 완료: 성공 $success / 실패 $failed'
                  : '업로드 완료: 성공 $success / 실패 $failed\n첫 실패: $firstError',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('파일 선택 실패: $e')));
      }
    }
  }

  Future<void> _uploadDroppedFiles(List<dynamic> events) async {
    if (_dropzone == null) return;
    if (events.isEmpty) return;

    setState(() {
      _isUploading = true;
      _isDragging = false;
      _bulkTotal = events.length;
      _bulkDone = 0;
    });

    int success = 0;
    int failed = 0;
    String? firstError;

    for (final event in events) {
      try {
        final name = await _dropzone!.getFilename(event);
        final mimeType = await _dropzone!.getFileMIME(event);
        final bytes = await _dropzone!.getFileData(event);

        final contentType = mimeType.toLowerCase();
        if (!_isSupportedImageContentType(contentType)) {
          failed++;
          firstError ??= '지원하지 않는 이미지 형식: $contentType ($name)';
          continue;
        }

        await ref
            .read(imageControllerProvider)
            .uploadImage(
              fileName: name,
              fileBytes: bytes,
              mimeType: contentType,
            );
        success++;
      } catch (e) {
        failed++;
        firstError ??= '$e';
      } finally {
        if (mounted) {
          setState(() => _bulkDone++);
        }
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstError == null
                ? '업로드 완료: 성공 $success / 실패 $failed'
                : '업로드 완료: 성공 $success / 실패 $failed\n첫 실패: $firstError',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      final bytes = await image.readAsBytes();
      final mimeType =
          _inferContentTypeFromName(image.name) ?? 'application/octet-stream';

      if (!_isSupportedImageContentType(mimeType)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('지원하지 않는 이미지 형식입니다: $mimeType')),
          );
        }
        return;
      }

      await ref
          .read(imageControllerProvider)
          .uploadImage(
            fileName: image.name,
            fileBytes: bytes,
            mimeType: mimeType,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지가 업로드되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageOptions(BuildContext context, String id, String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => ImageOptionsDialog(
        onFixMetadata: (ctx) async {
          final contentType = _inferContentTypeFromDownloadUrl(url);
          if (contentType == null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('URL에서 확장자를 추론할 수 없습니다.')),
            );
            return;
          }

          try {
            final ref = FirebaseStorage.instance.refFromURL(url);
            await ref.updateMetadata(
              SettableMetadata(contentType: contentType),
            );
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('메타데이터를 수정했습니다: $contentType')),
            );
          } catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(
              ctx,
            ).showSnackBar(SnackBar(content: Text('메타데이터 수정 실패: $e')));
          }
        },
        onCancel: () => Navigator.pop(dialogContext),
        onDelete: (ctx) async {
          Navigator.pop(ctx);
          try {
            await ref
                .read(imageControllerProvider)
                .deleteImage(id, originalUrl: url);
            if (mounted) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(const SnackBar(content: Text('이미지가 삭제되었습니다.')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
            }
          }
        },
      ),
    );
  }
}
