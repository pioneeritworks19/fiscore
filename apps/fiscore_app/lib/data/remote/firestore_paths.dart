part of '../../main.dart';

class FirestorePaths {
  const FirestorePaths._();

  static DocumentReference<Map<String, dynamic>> user(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId);
  }

  static DocumentReference<Map<String, dynamic>> tenant(String tenantId) {
    return FirebaseFirestore.instance.collection('tenants').doc(tenantId);
  }

  static CollectionReference<Map<String, dynamic>> members(String tenantId) {
    return tenant(tenantId).collection('members');
  }

  static DocumentReference<Map<String, dynamic>> member(
    String tenantId,
    String userId,
  ) {
    return members(tenantId).doc(userId);
  }

  static CollectionReference<Map<String, dynamic>> invites(String tenantId) {
    return tenant(tenantId).collection('invites');
  }

  static CollectionReference<Map<String, dynamic>> teamActivity(
    String tenantId,
  ) {
    return tenant(tenantId).collection('teamActivity');
  }

  static CollectionReference<Map<String, dynamic>> actionItems(
    String tenantId,
  ) {
    return tenant(tenantId).collection('actionItems');
  }

  static DocumentReference<Map<String, dynamic>> actionItem(
    String tenantId,
    String actionItemId,
  ) {
    return actionItems(tenantId).doc(actionItemId);
  }

  static CollectionReference<Map<String, dynamic>> sites(String tenantId) {
    return tenant(tenantId).collection('sites');
  }

  static DocumentReference<Map<String, dynamic>> site(
    String tenantId,
    String siteId,
  ) {
    return sites(tenantId).doc(siteId);
  }

  static DocumentReference<Map<String, dynamic>> siteInspection(
    String tenantId,
    String siteId,
    String inspectionId,
  ) {
    return siteInspections(tenantId, siteId).doc(inspectionId);
  }

  static CollectionReference<Map<String, dynamic>> siteInspections(
    String tenantId,
    String siteId,
  ) {
    return site(tenantId, siteId).collection('inspections');
  }

  static CollectionReference<Map<String, dynamic>> inspectionAttachments(
    String tenantId,
    String siteId,
    String inspectionId,
  ) {
    return siteInspection(
      tenantId,
      siteId,
      inspectionId,
    ).collection('attachments');
  }

  static CollectionReference<Map<String, dynamic>> internalAudits(
    String tenantId,
    String siteId,
  ) {
    return site(tenantId, siteId).collection('audits');
  }

  static DocumentReference<Map<String, dynamic>> internalAudit(
    String tenantId,
    String siteId,
    String auditId,
  ) {
    return internalAudits(tenantId, siteId).doc(auditId);
  }

  static CollectionReference<Map<String, dynamic>> auditResponses(
    String tenantId,
    String siteId,
    String auditId,
  ) {
    return internalAudit(tenantId, siteId, auditId).collection('responses');
  }

  static CollectionReference<Map<String, dynamic>> auditAttachments(
    String tenantId,
    String siteId,
    String auditId,
  ) {
    return internalAudit(tenantId, siteId, auditId).collection('attachments');
  }

  static CollectionReference<Map<String, dynamic>> auditAssignments(
    String tenantId,
    String siteId,
  ) {
    return site(tenantId, siteId).collection('auditAssignments');
  }

  static CollectionReference<Map<String, dynamic>> violations(
    String tenantId,
    String siteId,
  ) {
    return site(tenantId, siteId).collection('violations');
  }

  static DocumentReference<Map<String, dynamic>> violation(
    String tenantId,
    String siteId,
    String violationId,
  ) {
    return violations(tenantId, siteId).doc(violationId);
  }

  static CollectionReference<Map<String, dynamic>> violationThreads(
    String tenantId,
    String siteId,
    String violationId,
  ) {
    return violation(tenantId, siteId, violationId).collection('threads');
  }

  static CollectionReference<Map<String, dynamic>> trainingAssignments(
    String tenantId,
  ) {
    return tenant(tenantId).collection('trainingAssignments');
  }

  static CollectionReference<Map<String, dynamic>> trainings(String tenantId) {
    return tenant(tenantId).collection('trainings');
  }

  static CollectionReference<Map<String, dynamic>> checklistTemplates(
    String tenantId,
  ) {
    return tenant(tenantId).collection('checklistTemplates');
  }
}
