import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quote_model.dart';
import '../../data/repositories/quote_repository.dart';

// 전체 글 목록 (공식 콘텐츠)
final quoteListProvider = StreamProvider.family<List<QuoteModel>, ContentType?>(
  (ref, type) {
    return ref.watch(quoteRepositoryProvider).getQuotes(type: type);
  },
);

// 글모이 전체 (공식 + 사용자 제출)
final malmoiAllProvider = StreamProvider<List<QuoteModel>>((ref) {
  final repo = ref.watch(quoteRepositoryProvider);
  final officialStream = repo.getQuotes(type: ContentType.malmoi);
  final userStream = repo.getUserPosts();

  // 두 Stream을 결합 - 둘 중 하나라도 업데이트되면 재계산
  final controller = StreamController<List<QuoteModel>>();

  List<QuoteModel> latestOfficial = [];
  List<QuoteModel> latestUser = [];

  void emitCombined() {
    final userMalmoi = latestUser
        .where((q) => q.type == ContentType.malmoi)
        .toList();
    final combined = [...latestOfficial, ...userMalmoi];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    controller.add(combined);
  }

  final sub1 = officialStream.listen((official) {
    latestOfficial = official;
    emitCombined();
  });

  final sub2 = userStream.listen((user) {
    latestUser = user;
    emitCombined();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

// 한줄명언만
final quoteOnlyProvider = StreamProvider<List<QuoteModel>>((ref) {
  return ref.watch(quoteRepositoryProvider).getQuotes(type: ContentType.quote);
});

// 좋은생각만
final thoughtOnlyProvider = StreamProvider<List<QuoteModel>>((ref) {
  return ref
      .watch(quoteRepositoryProvider)
      .getQuotes(type: ContentType.thought);
});

// 글모이 (사용자 게시글)
final userPostsProvider = StreamProvider.family<List<QuoteModel>, bool?>((
  ref,
  isApproved,
) {
  return ref
      .watch(quoteRepositoryProvider)
      .getUserPosts(isApproved: isApproved);
});

// 신고된 글
final reportedPostsProvider = StreamProvider<List<QuoteModel>>((ref) {
  return ref.watch(quoteRepositoryProvider).getReportedPosts();
});

// 인기 글 TOP 5
final topPostsProvider = FutureProvider<List<QuoteModel>>((ref) {
  return ref.watch(quoteRepositoryProvider).getTopPosts();
});

final quoteControllerProvider = Provider((ref) {
  return QuoteController(ref);
});

class QuoteController {
  final Ref _ref;

  QuoteController(this._ref);

  Future<void> addQuote({
    required ContentType type,
    required String content,
    String author = '',
    String category = '일반',
    String? imageUrl,
    ContentFont font = ContentFont.gothic,
    ContentFontThickness fontThickness = ContentFontThickness.regular,
    MalmoiLength malmoiLength = MalmoiLength.short,
    bool isUserPost = false,
  }) async {
    final quote = QuoteModel(
      id: '', // Firestore will generate
      type: type,
      malmoiLength: type == ContentType.malmoi
          ? malmoiLength
          : MalmoiLength.short,
      content: content,
      author: author,
      category: category,
      imageUrl: imageUrl,
      font: font,
      fontThickness: fontThickness,
      createdAt: DateTime.now(),
      isUserPost: isUserPost,
    );
    if (!isUserPost) {
      await _ref.read(quoteRepositoryProvider).addOfficialQuoteDeduped(quote);
      return;
    }
    await _ref.read(quoteRepositoryProvider).addQuote(quote);
  }

  Future<void> updateQuote(QuoteModel quote) async {
    await _ref.read(quoteRepositoryProvider).updateQuote(quote);
  }

  Future<void> deleteQuote(String id) async {
    await _ref.read(quoteRepositoryProvider).deleteQuote(id);
  }

  // 사용자 게시글을 공식 콘텐츠로 격상
  Future<void> promoteUserPost(String id) async {
    await _ref.read(quoteRepositoryProvider).promoteUserPost(id);
  }

  // 노출 상태 토글
  Future<void> toggleActive(QuoteModel quote) async {
    await updateQuote(quote.copyWith(isActive: !quote.isActive));
  }

  // 승인 상태 변경
  Future<void> approvePost(QuoteModel quote) async {
    await updateQuote(quote.copyWith(isApproved: true));
  }

  Future<void> rejectPost(QuoteModel quote) async {
    await updateQuote(quote.copyWith(isApproved: false));
  }

  // 글 타입 변경 (글모이 → 좋은생각 등)
  Future<void> changeContentType(String id, ContentType newType) async {
    await _ref.read(quoteRepositoryProvider).changeContentType(id, newType);
  }
}
