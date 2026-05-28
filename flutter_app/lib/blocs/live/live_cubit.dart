import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import 'live_state.dart';

class LiveCubit extends Cubit<LiveState> {
  LiveCubit() : super(const LiveInitial());

  Future<void> load() async {
    emit(const LiveLoading());
    try {
      final results = await Future.wait([
        ApiService.getLiveSessions(),
        ApiService.getCommunityPosts(),
      ]);
      final allSessions = results[0] as List<LiveSession>;
      emit(LiveLoaded(
        liveRooms: allSessions.where((s) => s.status != 'ended').toList(),
        communityPosts: results[1] as List<CommunityPost>,
      ));
    } catch (_) {
      emit(const LiveError());
    }
  }

  Future<void> refresh() => load();

  /// Reload only community posts (used when filter/sort changes).
  Future<void> reloadPosts({String? category}) async {
    final current = state;
    if (current is! LiveLoaded) return;
    try {
      final posts =
          await ApiService.getCommunityPosts(category: category);
      emit(current.copyWith(communityPosts: posts));
    } catch (_) {
      // silently keep existing posts on error
    }
  }

  /// Optimistically toggle a like on a post.
  void toggleLike(String postId) {
    final current = state;
    if (current is! LiveLoaded) return;
    final updatedPosts = current.communityPosts.map((p) {
      if (p.id != postId) return p;
      return CommunityPost(
        id: p.id,
        authorName: p.authorName,
        content: p.content,
        likesCount: p.isLiked ? p.likesCount - 1 : p.likesCount + 1,
        commentsCount: p.commentsCount,
        isLiked: !p.isLiked,
        createdAt: p.createdAt,
        authorSign: p.authorSign,
        astrologerName: p.astrologerName,
        isVerified: p.isVerified,
      );
    }).toList();
    emit(current.copyWith(communityPosts: updatedPosts));
  }
}
