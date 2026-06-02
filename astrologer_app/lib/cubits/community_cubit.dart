import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/astrologer.dart';
import '../services/api_service.dart';

// --------------- State ---------------

class CommunityState {
  final bool loading;
  final bool submitting;
  final List<CommunityPost> posts;
  final String? filterCategory;
  final String sortBy;
  final String selectedCategory;

  const CommunityState({
    this.loading = true,
    this.submitting = false,
    this.posts = const [],
    this.filterCategory,
    this.sortBy = 'latest',
    this.selectedCategory = 'general',
  });

  List<CommunityPost> get sortedPosts {
    final list = List<CommunityPost>.from(posts);
    if (sortBy == 'liked') list.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    if (sortBy == 'commented') list.sort((a, b) => b.commentsCount.compareTo(a.commentsCount));
    return list;
  }

  bool get hasActiveFilter => filterCategory != null || sortBy != 'latest';

  CommunityState copyWith({
    bool? loading,
    bool? submitting,
    List<CommunityPost>? posts,
    String? Function()? filterCategory,
    String? sortBy,
    String? selectedCategory,
  }) =>
      CommunityState(
        loading: loading ?? this.loading,
        submitting: submitting ?? this.submitting,
        posts: posts ?? this.posts,
        filterCategory: filterCategory != null ? filterCategory() : this.filterCategory,
        sortBy: sortBy ?? this.sortBy,
        selectedCategory: selectedCategory ?? this.selectedCategory,
      );
}

// --------------- Cubit ---------------

class CommunityCubit extends Cubit<CommunityState> {
  CommunityCubit() : super(const CommunityState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final posts = await ApiService.getCommunityPosts(category: state.filterCategory);
      emit(state.copyWith(loading: false, posts: posts));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<bool> createPost(String text) async {
    if (text.isEmpty) return false;
    emit(state.copyWith(submitting: true));
    try {
      await ApiService.createPost(text, category: state.selectedCategory);
      emit(state.copyWith(submitting: false));
      await load();
      return true;
    } catch (_) {
      emit(state.copyWith(submitting: false));
      return false;
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await ApiService.deletePost(id);
      await load();
    } catch (_) {}
  }

  Future<void> toggleLike(String postId) async {
    await ApiService.toggleLike(postId);
    await load();
  }

  void setSelectedCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void applyFilter({required String? category, required String sort}) {
    emit(state.copyWith(
      filterCategory: () => category == 'all' ? null : category,
      sortBy: sort,
    ));
    load();
  }
}
