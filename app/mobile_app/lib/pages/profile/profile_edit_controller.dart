import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/file_service.dart';
import '../../services/image_compression_service.dart';

final _profileImagePickerProvider = Provider<ImagePicker>(
  (ref) => ImagePicker(),
);
final _profileFileServiceProvider = Provider<FileService>(
  (ref) => FileService(),
);

final profileEditControllerProvider = NotifierProvider.autoDispose
    .family<ProfileEditController, ProfileEditState, UserDto>(
      ProfileEditController.new,
    );

class ProfileEditState {
  const ProfileEditState({
    required this.avatarUrl,
    this.avatarFile,
    this.isSaving = false,
  });

  final String avatarUrl;
  final XFile? avatarFile;
  final bool isSaving;

  ProfileEditState copyWith({
    String? avatarUrl,
    XFile? avatarFile,
    bool clearAvatarFile = false,
    bool? isSaving,
  }) {
    return ProfileEditState(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarFile: clearAvatarFile ? null : avatarFile ?? this.avatarFile,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Riverpod-owned actions and state for the profile editor.
class ProfileEditController extends Notifier<ProfileEditState> {
  ProfileEditController(this.initialUser);

  final UserDto initialUser;

  @override
  ProfileEditState build() =>
      ProfileEditState(avatarUrl: initialUser.avatar ?? '');

  void generateRandomAvatar() {
    final seed = Random().nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
    state = state.copyWith(
      avatarUrl: 'https://api.dicebear.com/9.x/avataaars/svg?seed=$seed',
      clearAvatarFile: true,
    );
  }

  Future<void> pickFromGallery() => _pickImage(ImageSource.gallery);

  Future<void> takePhoto() => _pickImage(ImageSource.camera);

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ref
        .read(_profileImagePickerProvider)
        .pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    state = state.copyWith(avatarUrl: '', avatarFile: picked);
  }

  Future<void> submit({required String name, required String info}) async {
    state = state.copyWith(isSaving: true);
    CompressedImage? compressedAvatar;
    try {
      var avatar = state.avatarUrl;
      final avatarFile = state.avatarFile;
      if (avatarFile != null) {
        compressedAvatar = await ImageCompressionService.compress(
          avatarFile,
          quality: ImageCompressionService.avatarQuality,
          maxWidth: ImageCompressionService.avatarMaxWidth,
          maxHeight: ImageCompressionService.avatarMaxHeight,
        );
        final response = await ref
            .read(_profileFileServiceProvider)
            .uploadAvatar(ImageCompressionService.toXFile(compressedAvatar));
        final uploadedUrl = response.data;
        if (uploadedUrl == null || uploadedUrl.isEmpty) {
          throw const ProfileAvatarUploadException();
        }
        avatar = uploadedUrl;
      }

      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            UserUpdateDto(name: name.trim(), info: info.trim(), avatar: avatar),
          );
    } finally {
      if (compressedAvatar != null) {
        ImageCompressionService.cleanup([compressedAvatar]);
      }
      state = state.copyWith(isSaving: false);
    }
  }
}

class ProfileAvatarUploadException implements Exception {
  const ProfileAvatarUploadException();
}
