import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertTriangle, CheckCircle2, GraduationCap } from 'lucide-react';
import { subscribeTrainingAssignments } from './service';
import type { TrainingAssignment } from './types';
import type { Site } from '../sites/types';

export function TrainingPage({ tenantId, sites }: { tenantId: string; sites: Site[] }) {
  const { t } = useTranslation();
  const [assignments, setAssignments] = useState<TrainingAssignment[]>([]);
  const [statusFilter, setStatusFilter] = useState('active');
  const [siteFilter, setSiteFilter] = useState('all');
  const [queryText, setQueryText] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    return subscribeTrainingAssignments(tenantId, sites, setAssignments, setError);
  }, [tenantId, sites]);

  const activeCount = assignments.filter(isActiveTraining).length;
  const overdueCount = assignments.filter(isTrainingOverdue).length;
  const completedCount = assignments.filter((assignment) => assignment.status === 'completed').length;

  const visibleAssignments = assignments.filter((assignment) => {
    const matchesSite = siteFilter === 'all' || assignment.siteId === siteFilter;
    const status = assignment.status || 'assigned';
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && isActiveTraining(assignment)) ||
      (statusFilter === 'overdue' && isTrainingOverdue(assignment)) ||
      status === statusFilter;
    const blob = [
      assignment.trainingTitleSnapshot,
      assignment.trainingDescriptionSnapshot,
      assignment.assignedToNameSnapshot,
      assignment.assignedToEmailSnapshot,
      assignment.siteName,
      assignment.linkedViolationTitleSnapshot,
      status,
    ].join(' ').toLowerCase();
    return matchesSite && matchesStatus && (!queryText.trim() || blob.includes(queryText.trim().toLowerCase()));
  });

  return (
    <div className="page-stack compact-list-page">
      <section className="summary-strip" aria-label={t('trainingCommandCenter')}>
        <div>
          <GraduationCap size={17} />
          <strong>{activeCount}</strong>
          <span>{t('activeTraining')}</span>
        </div>
        <div className={overdueCount ? 'warning' : 'good'}>
          <AlertTriangle size={17} />
          <strong>{overdueCount}</strong>
          <span>{t('overdueTraining')}</span>
        </div>
        <div className="good">
          <CheckCircle2 size={17} />
          <strong>{completedCount}</strong>
          <span>{t('completedTraining')}</span>
        </div>
      </section>
      <section className="panel inspections-list-panel">
        <div className="list-panel-heading">
          <div>
            <p className="eyebrow">{t('trainingCommandCenter')}</p>
            <h2>{t('trainingHeadline')}</h2>
            <p>{t('trainingIntro')}</p>
          </div>
        </div>
        <div className="violations-toolbar compact-toolbar">
          <div className="filter-chips" role="group" aria-label={t('trainingFilters')}>
            {['active', 'overdue', 'completed', 'all'].map((filter) => (
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
              <input value={queryText} onChange={(event) => setQueryText(event.target.value)} placeholder={t('searchTrainingAssignments')} />
            </label>
          </div>
        </div>
        {error && <div className="status error">{error}</div>}
        <div className="violation-list">
          {visibleAssignments.map((assignment) => (
            <TrainingListRow key={assignment.id} assignment={assignment} />
          ))}
          {visibleAssignments.length === 0 && (
            <EmptyState icon={<GraduationCap size={22} />} title={t('emptyTrainingAssignmentsTitle')} body={t('emptyTrainingAssignmentsBody')} />
          )}
        </div>
      </section>
    </div>
  );
}

function TrainingListRow({ assignment }: { assignment: TrainingAssignment }) {
  const { t } = useTranslation();
  const dueDate = assignment.dueDate || assignment.dueAt;
  const overdue = isTrainingOverdue(assignment);
  const status = overdue ? 'overdue' : assignment.status || 'assigned';
  const progress = typeof assignment.progressPercent === 'number' ? `${assignment.progressPercent}%` : '';

  return (
    <article className="violation-row training-row">
      <span className={`severity-rail ${overdue ? 'medium' : assignment.status === 'completed' ? 'low' : ''}`} />
      <div className="violation-row-main">
        <div className="violation-row-title">
          <strong>{assignment.trainingTitleSnapshot || t('training')}</strong>
          <StatusBadge status={status} />
        </div>
        <p>
          {assignment.siteName || t('site')}
          {assignment.assignedToNameSnapshot ? ` - ${assignment.assignedToNameSnapshot}` : ''}
        </p>
        <div className="row-badges">
          {dueDate && <span>{t('due')}: {dateText(dueDate)}</span>}
          {progress && <span>{t('progress')}: {progress}</span>}
          {assignment.linkedViolationTitleSnapshot && <span>{assignment.linkedViolationTitleSnapshot}</span>}
          {assignment.completedAt && <span>{t('completed')}: {dateText(assignment.completedAt)}</span>}
        </div>
      </div>
    </article>
  );
}

function StatusBadge({ status }: { status: string }) {
  const { t } = useTranslation();
  return <span className={`status-badge ${status}`}>{t(status)}</span>;
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

function isActiveTraining(assignment: TrainingAssignment) {
  return !['completed', 'cancelled'].includes(assignment.status || 'assigned');
}

function isTrainingOverdue(assignment: TrainingAssignment) {
  if (!isActiveTraining(assignment)) return false;
  const value = assignment.dueDate || assignment.dueAt;
  const date =
    typeof value === 'string'
      ? new Date(value)
      : value && typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function'
        ? value.toDate()
        : null;
  if (!date || Number.isNaN(date.getTime())) return false;
  const today = new Date();
  const dueDay = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  const todayDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime();
  return dueDay < todayDay;
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
