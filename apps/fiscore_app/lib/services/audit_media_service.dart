part of '../main.dart';

class AuditMediaService {
  AuditMediaService({FirebaseStorage? storage, ImagePicker? picker})
      : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _picker;

  Future<String?> pickAndUploadPhoto({
    required String tenantId,
    required String siteId,
    required String auditId,
    required String responseId,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 76,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw const AppException('That photo is too large. Use an image under 10 MB.');
    }
    final attachmentRef =
        FirestorePaths.auditAttachments(tenantId, siteId, auditId).doc();
    final path =
        'tenants/$tenantId/sites/$siteId/audits/$auditId/attachments/${attachmentRef.id}/image.jpg';
    await _storage.ref(path).putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'tenantId': tenantId,
              'siteId': siteId,
              'auditId': auditId,
              'responseId': responseId,
              'attachmentId': attachmentRef.id,
            },
          ),
        );
    final now = FieldValue.serverTimestamp();
    await attachmentRef.set({
      'tenantId': tenantId,
      'siteId': siteId,
      'auditId': auditId,
      'responseId': responseId,
      'ownerType': 'audit_response',
      'type': 'image',
      'attachmentType': 'image',
      'contentType': 'image/jpeg',
      'storagePath': path,
      'thumbnailPath': path,
      'status': 'ready',
      'sizeBytes': bytes.length,
      'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
      'uploadedAt': now,
      'createdAt': now,
      'updatedAt': now,
    });
    return attachmentRef.id;
  }
}
