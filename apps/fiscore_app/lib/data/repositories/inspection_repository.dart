part of '../../main.dart';

class InspectionRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> streamForSite({
    required String tenantId,
    required String siteId,
  }) {
    return FirestorePaths.siteInspections(
      tenantId,
      siteId,
    ).orderBy('inspectionDate', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamReportAttachments({
    required String tenantId,
    required String siteId,
    required String inspectionId,
  }) {
    return FirestorePaths.inspectionAttachments(
      tenantId,
      siteId,
      inspectionId,
    )
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> uploadReportAttachment({
    required String tenantId,
    required String siteId,
    required String inspectionId,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'html', 'htm', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw const AppException('Could not read the selected report file.');
    }
    if (bytes.length > 15 * 1024 * 1024) {
      throw const AppException('Report files must be under 15 MB.');
    }

    final extension = _reportExtension(file.name);
    final contentType = _reportContentType(extension);
    final attachmentRef = FirestorePaths.inspectionAttachments(
      tenantId,
      siteId,
      inspectionId,
    ).doc();
    final storagePath =
        'tenants/$tenantId/sites/$siteId/inspections/$inspectionId/attachments/${attachmentRef.id}/report.$extension';

    await FirebaseStorage.instance.ref(storagePath).putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'tenantId': tenantId,
          'siteId': siteId,
          'inspectionId': inspectionId,
          'attachmentId': attachmentRef.id,
          'type': 'inspection_report',
        },
      ),
    );

    final now = FieldValue.serverTimestamp();
    await attachmentRef.set({
      'tenantId': tenantId,
      'siteId': siteId,
      'inspectionId': inspectionId,
      'ownerType': 'inspection',
      'type': 'inspection_report',
      'attachmentType': 'document',
      'displayName': file.name,
      'contentType': contentType,
      'storagePath': storagePath,
      'originalPath': storagePath,
      'viewablePath': storagePath,
      'viewableContentType': contentType,
      'sizeBytes': bytes.length,
      'source': 'user_upload',
      'status': 'ready',
      'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
      'uploadedAt': now,
      'createdAt': now,
      'updatedAt': now,
    });

    await FirestorePaths.siteInspection(tenantId, siteId, inspectionId).set({
      'tenantReportAttachmentId': attachmentRef.id,
      'tenantReportStoragePath': storagePath,
      'tenantReportStatus': 'available',
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  String _reportExtension(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    final cleaned = extension.replaceAll(RegExp('[^a-z0-9]'), '');
    return switch (cleaned) {
      'html' || 'htm' || 'png' || 'jpg' || 'jpeg' || 'pdf' => cleaned,
      _ => 'pdf',
    };
  }

  String _reportContentType(String extension) {
    return switch (extension) {
      'html' || 'htm' => 'text/html',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/pdf',
    };
  }
}
