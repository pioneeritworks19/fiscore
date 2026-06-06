import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertTriangle, ArrowRight, BarChart3, CheckCircle2, ClipboardCheck, FileText, History } from 'lucide-react';
import {
  subscribeAuditResponses,
  subscribeAuditsForSites,
  subscribePublicInspectionsForSites,
} from './service';
import type { Audit, AuditResponse, PublicInspection } from './types';
import type { Site } from '../sites/types';
import type { Violation } from '../violations/types';
import { getStorageDownloadUrl } from '../../shared/firebase/storage';
import { subscribeViolationsForAudit, subscribeViolationsForInspection } from '../violations/service';
import { ViolationDetailPage, ViolationListRow } from '../violations/ViolationsPage';

export function AuditsPage({ tenantId, sites }: { tenantId: string; sites: Site[] }) {
  const { t } = useTranslation();
  const [audits, setAudits] = useState<Audit[]>([]);
  const [selected, setSelected] = useState<Audit | null>(null);
  const [statusFilter, setStatusFilter] = useState('all');
  const [siteFilter, setSiteFilter] = useState('all');
  const [queryText, setQueryText] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setSelected(null);
    return subscribeAuditsForSites(tenantId, sites, setAudits, setError);
  }, [tenantId, sites]);

  const selectedAudit = selected
    ? audits.find((audit) => audit.id === selected.id && audit.siteId === selected.siteId) || selected
    : null;

  if (selectedAudit) {
    return <AuditDetailPage tenantId={tenantId} audit={selectedAudit} onBack={() => setSelected(null)} />;
  }

  const visibleAudits = audits.filter((audit) => {
    const matchesStatus = statusFilter === 'all' || audit.status === statusFilter;
    const matchesSite = siteFilter === 'all' || audit.siteId === siteFilter;
    const blob = [
      audit.templateNameSnapshot,
      audit.resultLabel,
      audit.siteName,
      audit.startedByDisplayNameSnapshot,
      audit.assignedToNameSnapshot,
    ].join(' ').toLowerCase();
    return matchesStatus && matchesSite && (!queryText.trim() || blob.includes(queryText.trim().toLowerCase()));
  });

  const completedCount = audits.filter((audit) => audit.status === 'completed').length;
  const inProgressCount = audits.filter((audit) => audit.status === 'in_progress').length;
  const withViolationsCount = audits.filter((audit) => auditViolationCount(audit) > 0).length;

  return (
    <div className="page-stack compact-list-page">
      <section className="summary-strip" aria-label={t('auditCommandCenter')}>
        <div className="good">
          <CheckCircle2 size={17} />
          <strong>{completedCount}</strong>
          <span>{t('completedAudits')}</span>
        </div>
        <div>
          <History size={17} />
          <strong>{inProgressCount}</strong>
          <span>{t('inProgressAudits')}</span>
        </div>
        <div className={withViolationsCount ? 'warning' : 'good'}>
          <AlertTriangle size={17} />
          <strong>{withViolationsCount}</strong>
          <span>{t('auditsWithViolations')}</span>
        </div>
      </section>
      <section className="panel inspections-list-panel">
        <div className="list-panel-heading">
          <div>
            <p className="eyebrow">{t('auditCommandCenter')}</p>
            <h2>{t('auditsHeadline')}</h2>
            <p>{t('auditsIntro')}</p>
          </div>
        </div>
        <div className="violations-toolbar compact-toolbar">
          <div className="filter-chips" role="group" aria-label={t('auditFilters')}>
            {['all', 'in_progress', 'completed', 'cancelled'].map((filter) => (
              <button
                key={filter}
                className={statusFilter === filter ? 'filter-chip active' : 'filter-chip'}
                onClick={() => setStatusFilter(filter)}
              >
                {t(filter)}
              </button>
            ))}
          </div>
          <div className="violations-controls">
            <label className="field compact-field">
              <span>{t('site')}</span>
              <select value={siteFilter} onChange={(event) => setSiteFilter(event.target.value)}>
                <option value="all">{t('allSites')}</option>
                {sites.map((site) => (
                  <option key={site.id} value={site.id}>{site.name}</option>
                ))}
              </select>
            </label>
            <label className="field compact-field">
              <span>{t('search')}</span>
              <input value={queryText} onChange={(event) => setQueryText(event.target.value)} placeholder={t('searchAudits')} />
            </label>
          </div>
        </div>
        {error && <div className="status error">{error}</div>}
        <div className="violation-list">
          {visibleAudits.map((audit) => (
            <AuditListRow key={`${audit.siteId}-${audit.id}`} audit={audit} onOpen={() => setSelected(audit)} />
          ))}
          {visibleAudits.length === 0 && (
            <EmptyState icon={<ClipboardCheck size={22} />} title={t('emptyAuditsTitle')} body={t('emptyAuditsBody')} />
          )}
        </div>
      </section>
    </div>
  );
}

function AuditListRow({ audit, onOpen }: { audit: Audit; onOpen: () => void }) {
  const { t } = useTranslation();
  const completed = audit.status === 'completed';
  const score = typeof audit.scorePercentage === 'number' ? `${audit.scorePercentage}%` : '';
  return (
    <button className="violation-row audit-row" onClick={onOpen}>
      <span className={`severity-rail ${auditViolationCount(audit) > 0 ? 'medium' : 'low'}`} />
      <div className="violation-row-main">
        <div className="violation-row-title">
          <strong>{audit.templateNameSnapshot || t('internalCheck')}</strong>
          <StatusBadge status={audit.status || 'in_progress'} />
        </div>
        <p>
          {audit.siteName || t('site')} - {dateText(completed ? audit.completedAt : audit.startedAt)}
        </p>
        <div className="row-badges">
          {score && <span>{t('scoreValue', { score })}</span>}
          {audit.resultLabel && <span>{audit.resultLabel}</span>}
          <span>{t('violationsCreated', { count: auditViolationCount(audit) })}</span>
          <span>{audit.startedByDisplayNameSnapshot || audit.assignedToNameSnapshot || t('teamMember')}</span>
        </div>
      </div>
      <ArrowRight size={18} />
    </button>
  );
}

function PublicInspectionListRow({
  inspection,
  onOpen,
}: {
  inspection: PublicInspection;
  onOpen: () => void;
}) {
  const { t } = useTranslation();
  const findings = inspectionFindingCount(inspection);
  const score = displayText(inspection.score);
  return (
    <button className="violation-row audit-row" onClick={onOpen}>
      <span className={`severity-rail ${findings > 0 ? 'medium' : 'low'}`} />
      <div className="violation-row-main">
        <div className="violation-row-title">
          <strong>{inspection.inspectionType || t('publicInspection')}</strong>
          <span className="status-badge in_progress">{dateText(inspection.inspectionDate) || t('inspectionDate')}</span>
        </div>
        <p>
          {inspection.siteName || t('site')}
          {inspection.sourceName ? ` - ${inspection.sourceName}` : ''}
        </p>
        <div className="row-badges">
          {inspection.grade && <span>{t('gradeValue', { grade: inspection.grade })}</span>}
          {score && <span>{t('scoreValue', { score })}</span>}
          {inspection.officialStatus && <span>{inspection.officialStatus}</span>}
          <span>{t('findingsCount', { count: findings })}</span>
          {(inspection.tenantReportStoragePath || inspection.reportUrl) && <span>{t('reportAvailable')}</span>}
        </div>
      </div>
      <ArrowRight size={18} />
    </button>
  );
}

export function PublicInspectionsPage({ tenantId, sites }: { tenantId: string; sites: Site[] }) {
  const { t } = useTranslation();
  const [inspections, setInspections] = useState<PublicInspection[]>([]);
  const [selectedInspection, setSelectedInspection] = useState<PublicInspection | null>(null);
  const [inspectionFilter, setInspectionFilter] = useState('all');
  const [siteFilter, setSiteFilter] = useState('all');
  const [queryText, setQueryText] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setSelectedInspection(null);
    return subscribePublicInspectionsForSites(tenantId, sites, setInspections, setError);
  }, [tenantId, sites]);

  const currentInspection = selectedInspection
    ? inspections.find(
        (inspection) =>
          inspection.id === selectedInspection.id && inspection.siteId === selectedInspection.siteId,
      ) || selectedInspection
    : null;

  if (currentInspection) {
    return (
      <PublicInspectionDetailPage
        tenantId={tenantId}
        inspection={currentInspection}
        onBack={() => setSelectedInspection(null)}
      />
    );
  }

  const visibleInspections = inspections.filter((inspection) => {
    const matchesSite = siteFilter === 'all' || inspection.siteId === siteFilter;
    const findings = inspectionFindingCount(inspection);
    const matchesFilter =
      inspectionFilter === 'all' ||
      (inspectionFilter === 'with_findings' && findings > 0) ||
      inspection.officialStatus === inspectionFilter ||
      inspection.grade === inspectionFilter;
    const blob = [
      inspection.siteName,
      inspection.inspectionType,
      inspection.officialStatus,
      inspection.grade,
      inspection.sourceName,
    ].join(' ').toLowerCase();
    return matchesSite && matchesFilter && (!queryText.trim() || blob.includes(queryText.trim().toLowerCase()));
  });

  const inspectionsWithFindings = inspections.filter((inspection) => inspectionFindingCount(inspection) > 0).length;
  const reportReadyCount = inspections.filter((inspection) => Boolean(inspection.tenantReportStoragePath || inspection.reportUrl)).length;

  return (
    <div className="page-stack compact-list-page">
      <section className="summary-strip" aria-label={t('publicInspectionCenter')}>
        <div>
          <FileText size={17} />
          <strong>{inspections.length}</strong>
          <span>{t('publicInspections')}</span>
        </div>
        <div className={inspectionsWithFindings ? 'warning' : 'good'}>
          <AlertTriangle size={17} />
          <strong>{inspectionsWithFindings}</strong>
          <span>{t('withFindings')}</span>
        </div>
        <div className="good">
          <CheckCircle2 size={17} />
          <strong>{reportReadyCount}</strong>
          <span>{t('reportsAvailable')}</span>
        </div>
      </section>
      <section className="panel inspections-list-panel">
        <div className="list-panel-heading">
          <div>
            <p className="eyebrow">{t('publicInspectionCenter')}</p>
            <h2>{t('publicInspectionsHeadline')}</h2>
            <p>{t('publicInspectionsIntro')}</p>
          </div>
        </div>
        <div className="violations-toolbar compact-toolbar">
          <div className="filter-chips" role="group" aria-label={t('publicInspectionFilters')}>
            {['all', 'with_findings'].map((filter) => (
              <button
                key={filter}
                className={inspectionFilter === filter ? 'filter-chip active' : 'filter-chip'}
                onClick={() => setInspectionFilter(filter)}
              >
                {t(filter)}
              </button>
            ))}
          </div>
          <div className="violations-controls">
            <label className="field compact-field">
              <span>{t('site')}</span>
              <select value={siteFilter} onChange={(event) => setSiteFilter(event.target.value)}>
                <option value="all">{t('allSites')}</option>
                {sites.map((site) => (
                  <option key={site.id} value={site.id}>{site.name}</option>
                ))}
              </select>
            </label>
            <label className="field compact-field">
              <span>{t('search')}</span>
              <input value={queryText} onChange={(event) => setQueryText(event.target.value)} placeholder={t('searchPublicInspections')} />
            </label>
          </div>
        </div>
        {error && <div className="status error">{error}</div>}
        <div className="violation-list">
          {visibleInspections.map((inspection) => (
            <PublicInspectionListRow
              key={`${inspection.siteId}-${inspection.id}`}
              inspection={inspection}
              onOpen={() => setSelectedInspection(inspection)}
            />
          ))}
          {visibleInspections.length === 0 && (
            <EmptyState icon={<FileText size={22} />} title={t('emptyPublicInspectionsTitle')} body={t('emptyPublicInspectionsBody')} />
          )}
        </div>
      </section>
    </div>
  );
}

function AuditDetailPage({ tenantId, audit, onBack }: { tenantId: string; audit: Audit; onBack: () => void }) {
  const { t } = useTranslation();
  const [responses, setResponses] = useState<AuditResponse[]>([]);
  const [violations, setViolations] = useState<Violation[]>([]);
  const siteId = audit.siteId || '';

  useEffect(() => {
    if (!siteId) return;
    const fail = () => {};
    const unsubs = [
      subscribeAuditResponses(tenantId, siteId, audit.id, setResponses, fail),
      subscribeViolationsForAudit(tenantId, siteId, audit.id, setViolations, fail),
    ];
    return () => unsubs.forEach((unsubscribe) => unsubscribe());
  }, [tenantId, siteId, audit.id]);

  const questions = auditQuestions(audit);
  const applicable = responses.filter((response) => response.answer && response.answer !== 'not_applicable');
  const passed = responses.filter((response) => response.answer === 'pass').length;
  const needsAttention = responses.filter((response) => response.answer === 'needs_attention').length;
  const notApplicable = responses.filter((response) => response.answer === 'not_applicable').length;
  const completed = responses.filter((response) => Boolean(response.answer)).length;

  return (
    <div className="page-stack violation-detail-page">
      <button className="link-button back-link" onClick={onBack}>
        <ArrowRight className="back-arrow" size={16} />
        {t('backToAudits')}
      </button>
      <section className="violation-hero">
        <div className="hero-badges">
          <StatusBadge status={audit.status || 'in_progress'} />
          {typeof audit.scorePercentage === 'number' && <span className="detail-chip low">{audit.scorePercentage}%</span>}
          {audit.resultLabel && <span className="detail-chip medium">{audit.resultLabel}</span>}
        </div>
        <h2>{audit.templateNameSnapshot || t('internalCheck')}</h2>
        <p>{audit.siteName}</p>
      </section>
      <div className="violation-detail-grid">
        <div className="detail-column">
          <DetailFactCard
            title={t('inspectionDetails')}
            icon={<ClipboardCheck size={18} />}
            facts={[
              [t('checkName'), audit.templateNameSnapshot],
              [t('status'), t(audit.status || 'in_progress')],
              [t('started'), dateText(audit.startedAt)],
              [t('completed'), dateText(audit.completedAt)],
              [t('completedBy'), audit.startedByDisplayNameSnapshot || audit.assignedToNameSnapshot],
              [t('score'), typeof audit.scorePercentage === 'number' ? `${audit.scorePercentage}%` : ''],
              [t('result'), audit.resultLabel],
            ]}
            emptyText={t('emptyInspectionDetails')}
          />
          <section className="detail-card">
            <div className="detail-card-title">
              <span><BarChart3 size={18} /></span>
              <h3>{t('workSummary')}</h3>
            </div>
            <p className="section-help">{t('workSummaryHelp')}</p>
            <div className="audit-summary-grid">
              <MiniStat label={t('questions')} value={questions.length || audit.answeredQuestionCount || completed} />
              <MiniStat label={t('answered')} value={audit.answeredQuestionCount || completed} />
              <MiniStat label={t('passed')} value={passed} />
              <MiniStat label={t('needsAttention')} value={needsAttention} />
              <MiniStat label={t('notApplicable')} value={notApplicable} />
              <MiniStat label={t('violations')} value={violations.length || auditViolationCount(audit)} />
            </div>
          </section>
        </div>
        <div className="detail-column">
          <section className="detail-card">
            <div className="detail-card-title">
              <span><AlertTriangle size={18} /></span>
              <h3>{t('violations')}</h3>
            </div>
            <p className="section-help">{t('auditViolationsHelp')}</p>
            <div className="violation-list compact">
              {violations.map((violation) => (
                <ViolationListRow key={violation.id} violation={{ ...violation, siteName: audit.siteName }} onOpen={() => {}} />
              ))}
              {violations.length === 0 && <p className="muted">{t('emptyAuditViolations')}</p>}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}

function PublicInspectionDetailPage({
  tenantId,
  inspection,
  onBack,
}: {
  tenantId: string;
  inspection: PublicInspection;
  onBack: () => void;
}) {
  const { t } = useTranslation();
  const [violations, setViolations] = useState<Violation[]>([]);
  const [selectedViolation, setSelectedViolation] = useState<Violation | null>(null);
  const siteId = inspection.siteId || '';
  const inspectionReference = inspection.masterInspectionId || inspection.id;

  useEffect(() => {
    if (!siteId || !inspectionReference) return;
    return subscribeViolationsForInspection(
      tenantId,
      siteId,
      inspectionReference,
      (items) => setViolations(items.map((violation) => ({ ...violation, siteName: inspection.siteName }))),
      () => {},
    );
  }, [tenantId, siteId, inspectionReference, inspection.siteName]);

  if (selectedViolation) {
    return (
      <ViolationDetailPage
        tenantId={tenantId}
        violation={selectedViolation}
        onBack={() => setSelectedViolation(null)}
      />
    );
  }

  return (
    <div className="page-stack inspection-detail-page">
      <button className="link-button back-link" onClick={onBack}>
        <ArrowRight className="back-arrow" size={16} />
        {t('backToPublicInspections')}
      </button>
      <section className="violation-hero inspection-hero">
        <div className="hero-badges">
          <span className="status-badge pending_review">{t('publicInspection')}</span>
          {inspection.grade && <span className="detail-chip low">{t('gradeValue', { grade: inspection.grade })}</span>}
          {displayText(inspection.score) && <span className="detail-chip medium">{t('scoreValue', { score: displayText(inspection.score) })}</span>}
        </div>
        <h2>{inspection.inspectionType || t('publicInspection')}</h2>
        <p>{inspection.siteName} {dateText(inspection.inspectionDate) ? `- ${dateText(inspection.inspectionDate)}` : ''}</p>
      </section>
      <div className="violation-detail-grid">
        <div className="detail-column">
          <DetailFactCard
            title={t('inspectionDetails')}
            icon={<FileText size={18} />}
            facts={[
              [t('site'), inspection.siteName],
              [t('inspectionDate'), dateText(inspection.inspectionDate)],
              [t('inspectionType'), inspection.inspectionType],
              [t('source'), inspection.sourceName || inspection.sourceSlug],
              [t('officialStatus'), inspection.officialStatus],
              [t('inspectionScore'), inspection.score],
              [t('inspectionGrade'), inspection.grade],
              [t('reportStatus'), inspection.tenantReportStatus || inspection.reportAvailabilityStatus],
            ]}
            emptyText={t('emptyInspectionDetails')}
          />
          <InspectionReportCard inspection={inspection} />
        </div>
        <div className="detail-column">
          <section className="detail-card inspection-violations-card">
            <div className="detail-card-title">
              <span><AlertTriangle size={18} /></span>
              <h3>{t('violations')}</h3>
            </div>
            <p className="section-help">{t('publicInspectionViolationsHelp')}</p>
            <div className="violation-list">
              {violations.map((violation) => (
                <ViolationListRow
                  key={violation.id}
                  violation={violation}
                  onOpen={() => setSelectedViolation(violation)}
                />
              ))}
              {violations.length === 0 && <p className="muted">{t('emptyPublicInspectionViolations')}</p>}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}

function InspectionReportCard({ inspection }: { inspection: PublicInspection }) {
  const { t } = useTranslation();
  const [opening, setOpening] = useState(false);
  const [error, setError] = useState('');
  const hasTenantReport = Boolean(inspection.tenantReportStoragePath);
  const hasSourceReport = Boolean(inspection.reportUrl);
  const reportStatus = inspection.tenantReportStatus || inspection.reportAvailabilityStatus;

  const openReport = async () => {
    setError('');
    setOpening(true);
    try {
      const url = inspection.tenantReportStoragePath
        ? await getStorageDownloadUrl(inspection.tenantReportStoragePath)
        : inspection.reportUrl;
      if (!url) {
        setError(t('noInspectionReport'));
        return;
      }
      window.open(url, '_blank', 'noopener,noreferrer');
    } catch {
      setError(t('couldNotOpenReport'));
    } finally {
      setOpening(false);
    }
  };

  return (
    <section className="detail-card report-card">
      <div className="detail-card-title">
        <span><FileText size={18} /></span>
        <h3>{t('report')}</h3>
      </div>
      {hasTenantReport || hasSourceReport ? (
        <div className="report-card-body">
          <div>
            <strong>{hasTenantReport ? t('tenantReportAvailable') : t('sourceReportAvailable')}</strong>
            <p>{t('inspectionReportHelp')}</p>
          </div>
          <div className="report-meta">
            {reportStatus && <span>{t('reportStatus')}: {t(reportStatus)}</span>}
            {inspection.reportFormat && <span>{t('reportFormat')}: {inspection.reportFormat}</span>}
          </div>
          <div className="report-actions">
            <button className="button primary" onClick={openReport} disabled={opening}>
              <FileText size={16} />
              {opening
                ? t('loading')
                : hasTenantReport
                  ? t('viewTenantReport')
                  : t('openSourceReport')}
            </button>
          </div>
          {error && <p className="form-error inline-error">{error}</p>}
        </div>
      ) : (
        <p className="muted">{t('noInspectionReport')}</p>
      )}
    </section>
  );
}

function MiniStat({ label, value }: { label: string; value: number | string }) {
  return (
    <div className="mini-stat">
      <strong>{value}</strong>
      <span>{label}</span>
    </div>
  );
}

function AuditResponseSummary({ responses }: { responses: AuditResponse[] }) {
  const { t } = useTranslation();
  const issueResponses = responses.filter((response) => response.answer === 'needs_attention');
  return (
    <section className="detail-card">
      <div className="detail-card-title">
        <span><FileText size={18} /></span>
        <h3>{t('responseSummary')}</h3>
      </div>
      {issueResponses.length === 0 ? (
        <p className="muted">{t('emptyResponseSummary')}</p>
      ) : (
        <div className="notes-list">
          {issueResponses.map((response) => (
            <div key={response.id} className="note-item">
              <strong>{response.questionPromptSnapshot || t('question')}</strong>
              <p>{response.note || t('needsAttention')}</p>
              <span>{response.sectionTitleSnapshot || severityLabel(response.severity || '')}</span>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

function auditQuestions(audit: Audit) {
  const sections = audit.templateSnapshot?.sections || [];
  return sections.flatMap((section) =>
    (section.questions || []).map((question) => ({
      ...question,
      sectionId: section.id,
      sectionTitle: section.title,
    })),
  );
}

function auditViolationCount(audit: Audit) {
  return audit.violationCount ?? audit.findingCount ?? audit.createdViolationIds?.length ?? 0;
}

function inspectionFindingCount(inspection: PublicInspection) {
  return inspection.findingCount ?? 0;
}

function StatusBadge({ status }: { status: string }) {
  const { t } = useTranslation();
  return <span className={`status-badge ${status}`}>{t(status)}</span>;
}

function displayText(value: unknown) {
  if (value === null || value === undefined) return '';
  if (typeof value === 'boolean') return value ? 'Yes' : 'No';
  if (typeof value === 'string') return value.trim();
  if (typeof value === 'number') return String(value);
  if (typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function') {
    return dateText(value);
  }
  return String(value);
}

function dateText(value: unknown) {
  const date =
    typeof value === 'string'
      ? new Date(value)
      : value && typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function'
        ? value.toDate()
        : null;
  if (!date || Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

function severityLabel(severity?: string) {
  if (!severity) return '';
  return severity.replaceAll('_', ' ').replace(/w/g, (letter) => letter.toUpperCase());
}

function DetailFactCard({
  title,
  icon,
  facts,
  emptyText,
}: {
  title: string;
  icon: ReactNode;
  facts: Array<[string, unknown]>;
  emptyText: string;
}) {
  const visibleFacts = facts
    .map(([label, value]) => [label, displayText(value)] as [string, string])
    .filter(([, value]) => value.length > 0);
  return (
    <section className="detail-card">
      <div className="detail-card-title">
        <span>{icon}</span>
        <h3>{title}</h3>
      </div>
      {visibleFacts.length === 0 ? (
        <p className="muted">{emptyText}</p>
      ) : (
        <div className="fact-list">
          {visibleFacts.map(([label, value]) => (
            <div key={label} className="fact-row">
              <span>{label}</span>
              <strong>{value}</strong>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

function SectionTitle({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div className="section-title">
      <h3>{title}</h3>
      {subtitle && <p>{subtitle}</p>}
    </div>
  );
}

function EmptyState({
  icon,
  title,
  body,
}: {
  icon: ReactNode;
  title: string;
  body: string;
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      <strong>{title}</strong>
      <p>{body}</p>
    </div>
  );
}
