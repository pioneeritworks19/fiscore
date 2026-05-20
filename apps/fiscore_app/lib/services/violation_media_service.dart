part of '../main.dart';

class ViolationMediaService {
  ViolationMediaService({FirebaseStorage? storage, ImagePicker? picker})
    : _storage = storage ?? FirebaseStorage.instance,
      _picker = picker ?? ImagePicker();

  static const int _maxImageEdge = 1600;
  static const int _thumbnailEdge = 360;
  static const int _imageQuality = 76;
  static const int _thumbnailQuality = 68;
  static const int _maxOriginalImageBytes = 10 * 1024 * 1024;
  static const int _maxVideoBytes = 25 * 1024 * 1024;
  static const Duration _maxVideoDuration = Duration(seconds: 45);

  final FirebaseStorage _storage;
  final ImagePicker _picker;

  Future<String?> pickAndUploadImage({
    required String tenantId,
    required String siteId,
    required String violationId,
    required String linkedContext,
    required ImageSource source,
    void Function(String attachmentId, Uint8List bytes)? onLocalPreview,
  }) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) {
      return null;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxOriginalImageBytes) {
      throw const AppException(
        'That photo is too large. Please use an image under 10 MB.',
      );
    }

    final attachmentRef = FirestorePaths.violation(
      tenantId,
      siteId,
      violationId,
    ).collection('attachments').doc();
    onLocalPreview?.call(attachmentRef.id, bytes);
    final basePath =
        'tenants/$tenantId/sites/$siteId/violations/$violationId/attachments/${attachmentRef.id}';
    final extension = _extensionForName(picked.name, fallback: 'jpg');
    final originalPath = '$basePath/original.$extension';
    final contentType = _imageContentType(extension);

    await attachmentRef.set({
      'tenantId': tenantId,
      'siteId': siteId,
      'violationId': violationId,
      'linkedContext': linkedContext,
      'ownerType': 'violation',
      'type': 'image',
      'attachmentType': 'image',
      'status': 'uploading',
      'contentType': contentType,
      'originalPath': originalPath,
      'storagePath': null,
      'compressedPath': null,
      'thumbnailPath': null,
      'sizeBytes': bytes.length,
      'originalFileName': picked.name,
      'originalSizeBytes': bytes.length,
      'processing': {
        'maxEdge': _maxImageEdge,
        'quality': _imageQuality,
        'thumbnailMaxEdge': _thumbnailEdge,
        'thumbnailQuality': _thumbnailQuality,
      },
      'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
      'uploadedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _storage
        .ref(originalPath)
        .putData(
          bytes,
          SettableMetadata(
            contentType: contentType,
            customMetadata: {
              'tenantId': tenantId,
              'siteId': siteId,
              'violationId': violationId,
              'linkedContext': linkedContext,
              'attachmentId': attachmentRef.id,
              'source': 'original',
            },
          ),
        );

    await attachmentRef.set({
      'status': 'processing',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return attachmentRef.id;
  }

  Future<String?> pickAndUploadVideo({
    required String tenantId,
    required String siteId,
    required String violationId,
    required String linkedContext,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickVideo(
      source: source,
      maxDuration: _maxVideoDuration,
    );
    if (picked == null) {
      return null;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxVideoBytes) {
      throw const AppException(
        'That video is too large. Please use a shorter clip under 25 MB.',
      );
    }

    final extension = _extensionForName(picked.name, fallback: 'mp4');
    final contentType = extension == 'mov' ? 'video/quicktime' : 'video/mp4';
    final attachmentRef = FirestorePaths.violation(
      tenantId,
      siteId,
      violationId,
    ).collection('attachments').doc();
    final videoPath =
        'tenants/$tenantId/sites/$siteId/violations/$violationId/attachments/${attachmentRef.id}/video.$extension';

    await _storage
        .ref(videoPath)
        .putData(
          bytes,
          SettableMetadata(
            contentType: contentType,
            customMetadata: {
              'tenantId': tenantId,
              'siteId': siteId,
              'violationId': violationId,
              'linkedContext': linkedContext,
              'sizeCapped': 'true',
            },
          ),
        );

    await attachmentRef.set({
      'tenantId': tenantId,
      'siteId': siteId,
      'violationId': violationId,
      'linkedContext': linkedContext,
      'ownerType': 'violation',
      'type': 'video',
      'attachmentType': 'video',
      'contentType': contentType,
      'storagePath': videoPath,
      'compressedPath': videoPath,
      'thumbnailPath': null,
      'sizeBytes': bytes.length,
      'originalFileName': picked.name,
      'originalSizeBytes': bytes.length,
      'compressedSizeBytes': bytes.length,
      'durationSeconds': null,
      'maxDurationSeconds': _maxVideoDuration.inSeconds,
      'sizeLimitBytes': _maxVideoBytes,
      'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
      'uploadedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return attachmentRef.id;
  }

  Future<void> deleteAttachment({
    required String tenantId,
    required String siteId,
    required String violationId,
    required String attachmentId,
  }) async {
    final attachmentRef = FirestorePaths.violation(
      tenantId,
      siteId,
      violationId,
    ).collection('attachments').doc(attachmentId);
    final snapshot = await attachmentRef.get();
    final data = snapshot.data();
    if (data == null) {
      return;
    }

    final paths = <String>{
      if (data['originalPath'] is String) data['originalPath'] as String,
      if (data['storagePath'] is String) data['storagePath'] as String,
      if (data['compressedPath'] is String) data['compressedPath'] as String,
      if (data['thumbnailPath'] is String) data['thumbnailPath'] as String,
    };
    await attachmentRef.delete();
    for (final path in paths) {
      await _deleteStorageObject(path);
    }
  }

  String _extensionForName(String fileName, {required String fallback}) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) {
      return fallback;
    }
    final extension = parts.last.replaceAll(RegExp('[^a-z0-9]'), '');
    return extension.isEmpty ? fallback : extension;
  }

  String _imageContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _deleteStorageObject(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found' &&
          error.code != 'unauthorized' &&
          error.code != 'permission-denied') {
        rethrow;
      }
    }
  }
}
