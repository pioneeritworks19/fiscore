import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import {
  AlertTriangle,
  ArrowRight,
  Camera,
  CheckCircle2,
  ClipboardCheck,
  FileText,
  GraduationCap,
  MessageSquare,
  PlayCircle,
  Users,
  X,
} from 'lucide-react';
import { getStorageDownloadUrl } from '../../shared/firebase/storage';
import type { Site } from '../sites/types';
import type { TrainingAssignment } from '../training/types';
import {
  subscribeViolationAttachments,
  subscribeViolationThread,
  subscribeViolationTrainingAssignments,
  subscribeViolationsForSites,
} from './service';
import type { Violation, ViolationAttachment, ViolationThreadEntry } from './types';

export function ViolationsPage({ tenantId, sites }: { tenantId: string; sites: Site[] }) {
  const { t } = useTranslation();
  const [violations, setViolations] = useState<Violation[]>([]);
  const [selected, setSelected] = useState<Violation | null>(null);
  const [statusFilter, setStatusFilter] = useState('active');
  const [siteFilter, setSiteFilter] = useState('all');
  const [queryText, setQueryText] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setSelected(null);
    return subscribeViolationsForSites(
      tenantId,
      sites,
      setViolations,
      (message) => setError(message),
    );
  }, [tenantId, sites]);

  const visibleViolations = violations.filter((violation) => {
    const status = violation.status || 'open';
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && ['open', 'in_progress'].includes(status)) ||
      (statusFilter === 'unassigned' &&
        ['open', 'in_progress'].includes(status) &&
        (!violation.assignedTo || violation.assignmentStatus === 'unassigned')) ||
      status === statusFilter;
    const matchesSite = siteFilter === 'all' || violation.siteId === siteFilter;
    const searchBlob = [
      violation.title,
      violation.summaryText,
      violation.officialCode,
      violation.clauseReference,
      violation.siteName,
      violation.description,
    ]
      .join(' ')
      .toLowerCase();
    const matchesSearch = !queryText.trim() || searchBlob.includes(queryText.trim().toLowerCase());
    return matchesStatus && matchesSite && matchesSearch;
  });

  const openCount = violations.filter((violation) => ['open', 'in_progress'].includes(violation.status || 'open')).length;
  const reviewCount = violations.filter((violation) => violation.status === 'pending_review').length;
  const unassignedCount = violations.filter(
    (violation) => ['open', 'in_progress'].includes(violation.status || 'open') && !violation.assignedTo,
  ).length;

  const selectedViolation = selected
    ? violations.find((violation) => violation.id === selected.id && violation.siteId === selected.siteId) || selected
    : null;

  if (selectedViolation) {
    return (
      <ViolationDetailPage
        tenantId={tenantId}
        violation={selectedViolation}
        onBack={() => setSelected(null)}
      />
    );
  }

  return (
    <div className="page-stack compact-list-page">
      <section className="summary-strip" aria-label={t('violationCommandCenter')}>
        <div className={openCount ? 'warning' : 'good'}>
          <AlertTriangle size={17} />
          <strong>{openCount}</strong>
          <span>{t('activeViolations')}</span>
        </div>
        <div>
          <ClipboardCheck size={17} />
          <strong>{reviewCount}</strong>
          <span>{t('awaitingReview')}</span>
        </div>
        <div className={unassignedCount ? 'warning' : 'good'}>
          <Users size={17} />
          <strong>{unassignedCount}</strong>
          <span>{t('unassigned')}</span>
        </div>
      </section>
      <section className="panel inspections-list-panel">
        <div className="list-panel-heading">
          <div>
            <p className="eyebrow">{t('violationCommandCenter')}</p>
            <h2>{t('violationsHeadline')}</h2>
            <p>{t('violationsIntro')}</p>
          </div>
        </div>
        <div className="violations-toolbar compact-toolbar">
          <div className="filter-chips" role="group" aria-label={t('violationFilters')}>
            {['active', 'unassigned', 'pending_review', 'closed', 'all'].map((filter) => (
              <button
                key={filter}
                className={statusFilter === filter ? 'filter-chip active' : 'filter-chip'}
                onClick={() => setStatusFilter(filter)}
              >
                {t(filter === 'pending_review' ? 'review' : filter)}
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
              <input value={queryText} onChange={(event) => setQueryText(event.target.value)} placeholder={t('searchViolations')} />
            </label>
          </div>
        </div>
        {error && <div className="status error">{error}</div>}
        <div className="violation-list">
          {visibleViolations.map((violation) => (
            <ViolationListRow
              key={`${violation.siteId}-${violation.id}`}
              violation={violation}
              onOpen={() => setSelected(violation)}
            />
          ))}
          {visibleViolations.length === 0 && (
            <EmptyState
              icon={<CheckCircle2 size={22} />}
              title={t('emptyViolationsTitle')}
              body={t('emptyViolationsBody')}
            />
          )}
        </div>
      </section>
    </div>
  );
}

export function ViolationListRow({ violation, onOpen }: { violation: Violation; onOpen: () => void }) {
  const { t } = useTranslation();
  const title = violationTitle(violation);
  const status = violation.status || 'open';
  const severity = severityLabel(violation.severity);
  const context = [sourceLabel(violation.sourceType), dateText(violation.inspectionDate)].filter(Boolean).join(' - ');

  return (
    <button className="violation-row" onClick={onOpen}>
      <span className={`severity-rail ${severityTone(severity)}`} />
      <div className="violation-row-main">
        <div className="violation-row-title">
          <strong>{title}</strong>
          <StatusBadge status={status} />
        </div>
        <p>{violation.siteName || t('site')} {context ? `- ${context}` : ''}</p>
        <div className="row-badges">
          {severity && <span>{severity}</span>}
          {violation.clauseReference && <span>{violation.clauseReference}</span>}
          <span>{violation.assignedToNameSnapshot || t('unassigned')}</span>
        </div>
      </div>
      <ArrowRight size={18} />
    </button>
  );
}

export function ViolationDetailPage({
  tenantId,
  violation,
  onBack,
}: {
  tenantId: string;
  violation: Violation;
  onBack: () => void;
}) {
  const { t } = useTranslation();
  const [attachments, setAttachments] = useState<ViolationAttachment[]>([]);
  const [thread, setThread] = useState<ViolationThreadEntry[]>([]);
  const [training, setTraining] = useState<TrainingAssignment[]>([]);
  const siteId = violation.siteId || '';

  useEffect(() => {
    if (!siteId) return;
    const fail = () => {};
    const unsubs = [
      subscribeViolationAttachments(tenantId, siteId, violation.id, setAttachments, fail),
      subscribeViolationThread(tenantId, siteId, violation.id, setThread, fail),
      subscribeViolationTrainingAssignments(tenantId, siteId, violation.id, setTraining, fail),
    ];
    return () => unsubs.forEach((unsubscribe) => unsubscribe());
  }, [tenantId, siteId, violation.id]);

  return (
    <div className="page-stack violation-detail-page">
      <button className="link-button back-link" onClick={onBack}>
        <ArrowRight className="back-arrow" size={16} />
        {t('backToViolations')}
      </button>
      <section className="violation-hero">
        <div className="hero-badges">
          <StatusBadge status={violation.status || 'open'} />
          {severityLabel(violation.severity) && <span className={`detail-chip ${severityTone(severityLabel(violation.severity))}`}>{severityLabel(violation.severity)}</span>}
        </div>
        <h2>{violationTitle(violation)}</h2>
        <p>{violation.siteName}</p>
      </section>
      {violation.status === 'pending_review' && (
        <div className="review-banner">
          <CheckCircle2 size={20} />
          <div>
            <strong>{t('readyForReview')}</strong>
            <p>{t('readyForReviewBody')}</p>
          </div>
        </div>
      )}
      <div className="violation-detail-grid">
        <div className="detail-column">
          <DetailFactCard
            title={t('sourceDetails')}
            icon={<FileText size={18} />}
            facts={[
              [t('source'), sourceLabel(violation.sourceType)],
              [t('inspectionDate'), dateText(violation.inspectionDate)],
              [t('inspectionType'), violation.inspectionType],
              [t('inspectionScore'), violation.inspectionScore],
              [t('inspectionGrade'), violation.inspectionGrade],
              [t('officialStatus'), violation.officialStatus],
            ]}
            emptyText={t('emptySourceDetails')}
          />
          <DetailFactCard
            title={t('violationDetails')}
            icon={<AlertTriangle size={18} />}
            facts={[
              [t('inspectorNote'), firstText(violation.auditorComments, violation.creatorComments, violation.comments, violation.description)],
              [t('section'), violation.sectionLabel],
              [t('category'), violation.normalizedCategory],
              [t('officialCode'), violation.officialCode],
              [t('clause'), firstText(violation.officialClauseReference, violation.clauseReference)],
              [t('question'), violation.questionLabel],
              [t('observedResponse'), violation.responseLabel],
              [t('severity'), severityLabel(violation.severity)],
              [t('officialText'), firstText(violation.officialText, violation.displayText, violation.summaryText)],
            ]}
            emptyText={t('emptyViolationDetails')}
          />
          <ResolutionCard violation={violation} />
        </div>
        <div className="detail-column">
          <ProofCard attachments={attachments} />
          <TrainingCard assignments={training} />
          <NotesCard entries={thread} />
        </div>
      </div>
    </div>
  );
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

function ResolutionCard({ violation }: { violation: Violation }) {
  const { t } = useTranslation();
  return (
    <section className="detail-card">
      <div className="detail-card-title">
        <span><ClipboardCheck size={18} /></span>
        <h3>{t('resolution')}</h3>
      </div>
      <p className="section-help">{t('resolutionHelp')}</p>
      <div className="assignment-line">
        <Users size={17} />
        <span>{violation.assignedToNameSnapshot || t('noOwnerAssigned')}</span>
      </div>
      <div className="fact-list">
        {[
          [t('whatWasFixed'), violation.responseCorrectiveAction],
          [t('extraNote'), violation.responseGeneral],
          [t('immediateContainment'), violation.responseContainment],
          [t('rootCause'), violation.responseRootCause],
          [t('preventiveAction'), violation.responsePreventiveAction],
        ].map(([label, value]) => (
          displayText(value).length > 0 && (
            <div key={label} className="fact-row">
              <span>{label}</span>
              <strong>{displayText(value)}</strong>
            </div>
          )
        ))}
      </div>
      {!violation.responseCorrectiveAction && <p className="muted">{t('emptyResolution')}</p>}
    </section>
  );
}

function ProofCard({ attachments }: { attachments: ViolationAttachment[] }) {
  const { t } = useTranslation();
  const proof = attachments.filter((attachment) => attachment.linkedContext === 'fix');
  const [preview, setPreview] = useState<{ url: string; type: string; label: string } | null>(null);
  return (
    <section className="detail-card">
      <div className="detail-card-title">
        <span><Camera size={18} /></span>
        <h3>{t('proof')}</h3>
      </div>
      <p className="section-help">{t('proofHelp')}</p>
      {proof.length === 0 ? (
        <p className="muted">{t('emptyProof')}</p>
      ) : (
        <div className="proof-grid">
          {proof.map((attachment) => (
            <ProofMediaTile
              key={attachment.id}
              attachment={attachment}
              onOpen={setPreview}
            />
          ))}
        </div>
      )}
      {preview && (
        <div className="media-lightbox" role="dialog" aria-modal="true" aria-label={preview.label}>
          <button className="media-lightbox-backdrop" onClick={() => setPreview(null)} aria-label={t('cancel')} />
          <div className="media-lightbox-content">
            <button className="icon-button media-close" onClick={() => setPreview(null)} aria-label={t('cancel')}>
              <X size={20} />
            </button>
            {preview.type === 'video' ? (
              <video src={preview.url} controls autoPlay />
            ) : (
              <img src={preview.url} alt={preview.label} />
            )}
          </div>
        </div>
      )}
    </section>
  );
}

function ProofMediaTile({
  attachment,
  onOpen,
}: {
  attachment: ViolationAttachment;
  onOpen: (preview: { url: string; type: string; label: string }) => void;
}) {
  const { t } = useTranslation();
  const [url, setUrl] = useState(attachment.downloadUrl || '');
  const [error, setError] = useState('');
  const type = attachmentMediaType(attachment);
  const label = attachment.displayName || (type === 'video' ? t('videoAttached') : t('imageAttached'));
  const path = attachmentPreviewPath(attachment);

  useEffect(() => {
    let alive = true;
    setError('');
    if (attachment.downloadUrl) {
      setUrl(attachment.downloadUrl);
      return;
    }
    if (!path) return;
    getStorageDownloadUrl(path)
      .then((downloadUrl) => {
        if (alive) setUrl(downloadUrl);
      })
      .catch(() => {
        if (alive) setError(t('couldNotLoadMedia'));
      });
    return () => {
      alive = false;
    };
  }, [attachment.downloadUrl, path, t]);

  return (
    <button
      className="proof-tile"
      onClick={() => url && onOpen({ url, type, label })}
      disabled={!url}
      aria-label={`${t('openProofMedia')}: ${label}`}
    >
      <span className="proof-thumb">
        {url && type === 'image' && <img src={url} alt="" loading="lazy" />}
        {url && type === 'video' && <video src={url} muted preload="metadata" />}
        {!url && !error && <Camera size={24} />}
        {error && <AlertTriangle size={22} />}
        {type === 'video' && (
          <span className="play-pill">
            <PlayCircle size={24} />
          </span>
        )}
      </span>
      <span className="proof-caption">
        <strong>{label}</strong>
        <small>{error || (type === 'video' ? t('videoAttached') : t('imageAttached'))}</small>
      </span>
    </button>
  );
}

function TrainingCard({ assignments }: { assignments: TrainingAssignment[] }) {
  const { t } = useTranslation();
  return (
    <section className="detail-card">
      <div className="detail-card-title">
        <span><GraduationCap size={18} /></span>
        <h3>{t('training')}</h3>
      </div>
      <p className="section-help">{t('trainingHelp')}</p>
      {assignments.length === 0 ? (
        <p className="muted">{t('emptyTraining')}</p>
      ) : (
        <div className="attachment-list">
          {assignments.map((assignment) => (
            <div key={assignment.id} className="training-item">
              <strong>{assignment.trainingTitleSnapshot || t('training')}</strong>
              <p>{assignment.assignedToNameSnapshot || assignment.assignedToEmailSnapshot || t('teamMember')} - {t(assignment.status || 'active')}</p>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

function NotesCard({ entries }: { entries: ViolationThreadEntry[] }) {
  const { t } = useTranslation();
  return (
    <section className="detail-card">
      <div className="detail-card-title">
        <span><MessageSquare size={18} /></span>
        <h3>{t('notes')}</h3>
      </div>
      <p className="section-help">{t('notesHelp')}</p>
      {entries.length === 0 ? (
        <p className="muted">{t('emptyNotes')}</p>
      ) : (
        <div className="notes-thread">
          {entries.slice(0, 8).map((entry) => (
            <div key={entry.id} className="note-message">
              <div className="note-avatar">{initialsFor(entry.createdByDisplayNameSnapshot || entry.createdBy || t('fiscoreUser'))}</div>
              <div className="note-bubble">
                <div className="note-meta">
                  <strong>{entry.createdByDisplayNameSnapshot || entry.createdBy || t('fiscoreUser')}</strong>
                  <span>{dateText(entry.createdAt)}</span>
                </div>
                <p>{entry.body}</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

function attachmentMediaType(attachment: ViolationAttachment) {
  const type = (attachment.attachmentType || attachment.type || '').toLowerCase();
  const path = attachmentPreviewPath(attachment).toLowerCase();
  if (type.includes('video') || /\.(mp4|mov|webm)$/i.test(path)) return 'video';
  return 'image';
}

function attachmentPreviewPath(attachment: ViolationAttachment) {
  return firstText(
    attachment.thumbnailPath,
    attachment.compressedPath,
    attachment.storagePath,
    attachment.originalPath,
  );
}


function StatusBadge({ status }: { status: string }) {
  const { t } = useTranslation();
  return <span className={`status-badge ${status}`}>{t(status)}</span>;
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

function violationTitle(violation: Violation) {
  return firstText(violation.title, violation.summaryText, 'Violation finding');
}

function firstText(...values: unknown[]) {
  return values.map(displayText).find((value) => value.length > 0) || '';
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

function sourceLabel(sourceType?: string) {
  if (sourceType === 'internal_audit') return 'Internal check';
  if (sourceType === 'public_inspection_finding') return 'Public inspection';
  return sourceType ? sourceType.replaceAll('_', ' ') : '';
}

function severityLabel(severity?: string) {
  if (!severity) return '';
  return severity.replaceAll('_', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function severityTone(severity: string) {
  const normalized = severity.toLowerCase();
  if (normalized.includes('critical') || normalized.includes('high')) return 'high';
  if (normalized.includes('medium') || normalized.includes('normal')) return 'medium';
  return 'low';
}

function initialsFor(value: string) {
  const parts = value
    .replace(/@.*/, '')
    .split(/[.\s_-]+/)
    .filter(Boolean);
  return (parts[0]?.[0] || 'F').toUpperCase() + (parts[1]?.[0] || '').toUpperCase();
}
