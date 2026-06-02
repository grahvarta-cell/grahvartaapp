import 'package:flutter_bloc/flutter_bloc.dart';

// --------------- State ---------------

class OwnProfileState {
  final bool editing;
  final bool saving;
  final bool uploadingAvatar;

  const OwnProfileState({
    this.editing = false,
    this.saving = false,
    this.uploadingAvatar = false,
  });

  OwnProfileState copyWith({
    bool? editing,
    bool? saving,
    bool? uploadingAvatar,
  }) =>
      OwnProfileState(
        editing: editing ?? this.editing,
        saving: saving ?? this.saving,
        uploadingAvatar: uploadingAvatar ?? this.uploadingAvatar,
      );
}

// --------------- Cubit ---------------

class OwnProfileCubit extends Cubit<OwnProfileState> {
  OwnProfileCubit() : super(const OwnProfileState());

  void startEditing() => emit(state.copyWith(editing: true));

  void cancelEditing() => emit(state.copyWith(editing: false));

  void setSaving(bool value) => emit(state.copyWith(saving: value));

  void setUploadingAvatar(bool value) => emit(state.copyWith(uploadingAvatar: value));

  void doneEditing() => emit(state.copyWith(editing: false, saving: false));
}
