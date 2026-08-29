import 'dart:io';

import 'package:feedback_sdk/feedback_sdk.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import '../../ui/app_feedback.dart';
import '../../ui/app_fields.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

/// 匿名反馈表单页：描述 + 联系方式 + 图片（≤6）+ 字数统计 + 提交。
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<XFile> _images = [];

  bool _submitting = false;
  int _contentLength = 0;

  /// 幂等 request_id：同一份内容重试时复用，内容变更时重置。
  String? _requestId;

  FeedbackConfig get _config => FeedbackSdk.instance.config;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _markDirty() => _requestId = null;

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    final remaining = _config.maxImageCount - _images.length;
    if (remaining <= 0) {
      await AppFeedback.showError(context, message: l10n.feedbackImageTooMany);
      return;
    }

    try {
      final picked = await _imagePicker.pickMultiImage();
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _images.addAll(picked.take(remaining));
        _requestId = null;
      });
      // 一次选超了会静默截断，这里补一句提示，避免用户困惑「怎么少了几张」。
      if (picked.length > remaining) {
        await AppFeedback.showError(context, message: l10n.feedbackImageTooMany);
      }
    } catch (_) {
      if (!mounted) return;
      await AppFeedback.showError(
        context,
        message: l10n.feedbackPickImageFailed,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _requestId = null;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final content = _contentController.text.trim();
    final contact = _contactController.text.trim();

    if (content.isEmpty) {
      await AppFeedback.showError(
        context,
        message: l10n.feedbackContentRequired,
      );
      return;
    }
    if (contact.isEmpty) {
      await AppFeedback.showError(
        context,
        message: l10n.feedbackContactRequired,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // 三段式上传每张图片，收集 attachment_id。
      final attachmentIds = <int>[];
      for (final file in _images) {
        final bytes = await file.readAsBytes();
        attachmentIds.add(await FeedbackSdk.instance.uploadImage(
          filename: file.name,
          raw: bytes,
        ));
      }

      // 复用同一 request_id 保证失败重试幂等。
      _requestId ??= FeedbackSdk.instance.newRequestId();
      await FeedbackSdk.instance.submit(
        content: content,
        contact: contact,
        attachmentIds: attachmentIds,
        page: 'FeedbackScreen',
        requestId: _requestId,
      );

      if (!mounted) return;
      await AppFeedback.showSuccess(context, message: l10n.feedbackSubmitSuccess);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FeedbackException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await AppFeedback.showError(context, message: e.userMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await AppFeedback.showError(
        context,
        message: FeedbackApi.toFeedback(e).userMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.feedbackTitle),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Text(l10n.feedbackSubtitle, style: AppTextStyles.muted(context)),
            const SizedBox(height: 24),
            _fieldLabel(context, l10n.feedbackContentLabel, required: true),
            const SizedBox(height: 8),
            AppTextField(
              controller: _contentController,
              placeholder: l10n.feedbackContentPlaceholder,
              maxLines: 6,
              maxLength: _config.maxContentLength,
              onChanged: (v) => setState(() {
                _contentLength = v.length;
                _requestId = null;
              }),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  '$_contentLength/${_config.maxContentLength}',
                  style: AppTextStyles.label(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _fieldLabel(context, l10n.feedbackContactLabel, required: true),
            const SizedBox(height: 8),
            AppTextField(
              controller: _contactController,
              placeholder: l10n.feedbackContactPlaceholder,
              maxLength: _config.maxContactLength,
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 20),
            _fieldLabel(context, l10n.feedbackImagesLabel),
            const SizedBox(height: 8),
            _buildImageGrid(context),
            const SizedBox(height: 32),
            AppPrimaryButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? l10n.feedbackSubmitting : l10n.submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(
    BuildContext context,
    String text, {
    bool required = false,
  }) {
    return Row(
      children: [
        Text(text, style: AppTextStyles.label(context).copyWith(fontSize: 13)),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              color: CupertinoDynamicColor.resolve(
                AppColors.destructive,
                context,
              ),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _images.length; i++) _buildImageThumb(context, i),
        if (_images.length < _config.maxImageCount) _buildAddTile(context),
      ],
    );
  }

  Widget _buildAddTile(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: _pickImages,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(AppColors.secondary, context),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: CupertinoDynamicColor.resolve(AppColors.border, context),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.plus,
              color: CupertinoDynamicColor.resolve(
                AppColors.mutedForeground,
                context,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).feedbackAddImage,
              style: AppTextStyles.label(context).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumb(BuildContext context, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Image.file(
            File(_images[index].path),
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xCC000000),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 12,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
