part of '../../main.dart';

class Violation {
  const Violation({
    required this.id,
    required this.siteId,
    required this.title,
    required this.status,
    required this.sourceType,
    required this.inspectionDate,
    required this.clauseReference,
  });

  final String id;
  final String siteId;
  final String title;
  final String status;
  final String? sourceType;
  final String inspectionDate;
  final String? clauseReference;

  factory Violation.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return Violation(
      id: snapshot.id,
      siteId: data['siteId'] as String? ?? '',
      title: data['title'] as String? ??
          data['summaryText'] as String? ??
          'Violation finding',
      status: data['status'] as String? ?? 'open',
      sourceType: data['sourceType'] as String?,
      inspectionDate: _dateText(data['inspectionDate']),
      clauseReference: data['clauseReference'] as String?,
    );
  }
}
