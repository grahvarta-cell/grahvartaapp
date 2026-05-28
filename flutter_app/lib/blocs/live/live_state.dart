import 'package:equatable/equatable.dart';
import '../../models/astrologer.dart';

abstract class LiveState extends Equatable {
  const LiveState();
  @override
  List<Object?> get props => [];
}

class LiveInitial extends LiveState {
  const LiveInitial();
}

class LiveLoading extends LiveState {
  const LiveLoading();
}

class LiveError extends LiveState {
  const LiveError();
}

class LiveLoaded extends LiveState {
  final List<LiveSession> liveRooms;
  final List<CommunityPost> communityPosts;

  const LiveLoaded({
    this.liveRooms = const [],
    this.communityPosts = const [],
  });

  LiveLoaded copyWith({
    List<LiveSession>? liveRooms,
    List<CommunityPost>? communityPosts,
  }) =>
      LiveLoaded(
        liveRooms: liveRooms ?? this.liveRooms,
        communityPosts: communityPosts ?? this.communityPosts,
      );

  @override
  List<Object?> get props => [liveRooms, communityPosts];
}
