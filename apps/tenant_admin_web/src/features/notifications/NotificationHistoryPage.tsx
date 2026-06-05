import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertTriangle, ArrowRight, Bell, History, Mail } from 'lucide-react';
import {
  subscribeNotificationDeliveryAttempts,
  subscribeNotificationEvents,
} from './service';
import type { NotificationDeliveryAttempt, NotificationEvent } from './types';

export function NotificationHistoryPage({ tenantId }: { tenantId: string }) {
  const { t } = useTranslation();
  const [events, setEvents] = useState<NotificationEvent[]>([]);
  const [attempts, setAttempts] = useState<NotificationDeliveryAttempt[]>([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [eventFilter, setEventFilter] = useState('all');
  const [selected, setSelected] = useState<NotificationEvent | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setSelected(null);
    return subscribeNotificationEvents(tenantId, statusFilter, setEvents, setError);
  }, [tenantId, statusFilter]);

  useEffect(() => {
    if (!selected) {
      setAttempts([]);
      return;
    }
    return subscribeNotificationDeliveryAttempts(tenantId, selected.id, setAttempts, setError);
  }, [tenantId, selected]);

  const eventTypes = Array.from(new Set(events.map((event) => event.eventType).filter(Boolean))).sort();
  const filteredEvents = events.filter((event) => eventFilter === 'all' || event.eventType === eventFilter);
  const sentCount = events.filter((event) => event.status === 'sent').length;
  const failedCount = events.filter((event) => event.status === 'failed').length;
  const suppressedCount = events.filter((event) => ['skipped', 'suppressed'].includes(event.status || '')).length;

  if (selected) {
    return (
      <NotificationDetailPage
        event={selected}
        attempts={attempts}
        onBack={() => setSelected(null)}
      />
    );
  }

  return (
    <div className="page-stack compact-list-page notification-page">
      <section className="summary-strip" aria-label={t('notificationHistory')}>
        <div className="good">
          <Mail size={17} />
          <strong>{sentCount}</strong>
          <span>{t('notificationStatusSent')}</span>
        </div>
        <div className={failedCount ? 'warning' : 'good'}>
          <AlertTriangle size={17} />
          <strong>{failedCount}</strong>
          <span>{t('notificationStatusFailed')}</span>
        </div>
        <div>
          <Bell size={17} />
          <strong>{suppressedCount}</strong>
          <span>{t('notificationStatusSuppressed')}</span>
        </div>
      </section>
      {error && <div className="status error">{error}</div>}
      <section className="panel inspections-list-panel notification-list-panel">
        <div className="list-panel-heading">
          <div>
            <p className="eyebrow">{t('notificationHistory')}</p>
            <h2>{t('notificationsHeadline')}</h2>
            <p>{t('notificationsIntro')}</p>
          </div>
        </div>
        <div className="notification-toolbar compact-toolbar">
          <div className="filter-chips" role="group" aria-label={t('status')}>
            {['all', 'sent', 'failed', 'skipped', 'suppressed', 'pending'].map((filter) => (
              <button
                key={filter}
                className={statusFilter === filter ? 'filter-chip active' : 'filter-chip'}
                onClick={() => setStatusFilter(filter)}
              >
                {filter === 'all' ? t('all') : notificationStatusLabel(t, filter)}
              </button>
            ))}
          </div>
          <label className="field compact-field">
            <span>{t('eventType')}</span>
            <select value={eventFilter} onChange={(event) => setEventFilter(event.target.value)}>
              <option value="all">{t('allEventTypes')}</option>
              {eventTypes.map((eventType) => (
                <option key={eventType} value={eventType}>
                  {notificationEventLabel(t, eventType)}
                </option>
              ))}
            </select>
          </label>
        </div>
        <div className="notification-list">
          {filteredEvents.map((event) => (
            <button
              key={event.id}
              className="notification-row"
              onClick={() => setSelected(event)}
            >
              <span className={`severity-rail ${notificationStatusTone(event.status)}`} />
              <div className="violation-row-main">
                <div className="notification-row-title">
                  <strong>{notificationEventLabel(t, event.eventType)}</strong>
                  <span className={`status-badge ${notificationStatusTone(event.status)}`}>
                    {notificationStatusLabel(t, event.status)}
                  </span>
                </div>
                <p>{event.recipientEmail || event.recipientUserId || t('unknownRecipient')}</p>
                <div className="row-badges">
                  <span>{dateTimeText(event.createdAt)}</span>
                  {event.channel && <span>{event.channel}</span>}
                  {event.targetType && <span>{humanizeToken(event.targetType)}</span>}
                </div>
              </div>
              <ArrowRight size={17} />
            </button>
          ))}
          {filteredEvents.length === 0 && (
            <EmptyState
              icon={<Bell size={22} />}
              title={t('emptyNotificationsTitle')}
              body={t('emptyNotificationsBody')}
            />
          )}
        </div>
      </section>
    </div>
  );
}

function NotificationDetailPage({
  event,
  attempts,
  onBack,
}: {
  event: NotificationEvent;
  attempts: NotificationDeliveryAttempt[];
  onBack: () => void;
}) {
  const { t } = useTranslation();
  const latestRenderedAttempt = attempts.find((attempt) => attempt.renderedText || attempt.renderedHtml || attempt.renderedSubject);
  const renderedSubject = event.renderedSubject || latestRenderedAttempt?.renderedSubject || '';
  const renderedText = event.renderedText || latestRenderedAttempt?.renderedText || '';

  return (
    <div className="page-stack notification-detail-page">
      <button className="link-button back-link" onClick={onBack}>
        <ArrowRight className="back-arrow" size={16} />
        {t('backToNotifications')}
      </button>
      <section className="violation-hero notification-hero">
        <div className="hero-badges">
          <span className={`status-badge ${notificationStatusTone(event.status)}`}>
            {notificationStatusLabel(t, event.status)}
          </span>
          {event.channel && <span className="detail-chip medium">{event.channel}</span>}
          {event.targetType && <span className="detail-chip low">{humanizeToken(event.targetType)}</span>}
        </div>
        <h2>{notificationEventLabel(t, event.eventType)}</h2>
        <p>{event.recipientEmail || event.recipientUserId || t('unknownRecipient')}</p>
      </section>
      <div className="notification-detail-grid">
        <div className="notification-detail-stack">
          <DetailFactCard
            title={t('notificationDetails')}
            icon={<Bell size={18} />}
            emptyText={t('emptyNotificationDetails')}
            facts={[
              [t('eventType'), notificationEventLabel(t, event.eventType)],
              [t('status'), notificationStatusLabel(t, event.status)],
              [t('recipient'), event.recipientEmail || event.recipientUserId],
              [t('reason'), event.reason],
              [t('channel'), event.channel],
              [t('template'), event.templateId],
              [t('locale'), event.locale],
              [t('target'), [event.targetType, event.targetId].filter(Boolean).join(' / ')],
              [t('created'), dateTimeText(event.createdAt)],
              [t('sent'), dateTimeText(event.sentAt)],
              [t('provider'), event.provider],
              [t('providerMessageId'), event.providerMessageId],
              [t('dedupeHash'), event.dedupeHash],
            ]}
          />
          <section className="detail-card">
            <div className="detail-card-title">
              <span><History size={18} /></span>
              <h3>{t('deliveryAttempts')}</h3>
            </div>
            {attempts.length === 0 ? (
              <p className="muted">{t('emptyDeliveryAttempts')}</p>
            ) : (
              <div className="attempt-list">
                {attempts.map((attempt) => (
                  <div key={attempt.id} className="attempt-row">
                    <div>
                      <strong>{notificationStatusLabel(t, attempt.status)}</strong>
                      <p>{dateTimeText(attempt.completedAt || attempt.attemptedAt || attempt.createdAt)}</p>
                    </div>
                    <div className="row-badges">
                      {attempt.provider && <span>{attempt.provider}</span>}
                      {attempt.channel && <span>{attempt.channel}</span>}
                      {attempt.providerMessageId && <span>{attempt.providerMessageId}</span>}
                    </div>
                    {(attempt.errorCode || attempt.errorMessage) && (
                      <p className="error-text">{[attempt.errorCode, attempt.errorMessage].filter(Boolean).join(': ')}</p>
                    )}
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>
        <section className="detail-card email-preview-card">
          <div className="detail-card-title">
            <span><Mail size={18} /></span>
            <h3>{t('emailPreview')}</h3>
          </div>
          {renderedSubject || renderedText ? (
            <div className="email-preview">
              {renderedSubject && (
                <div className="fact-row">
                  <span>{t('subject')}</span>
                  <strong>{renderedSubject}</strong>
                </div>
              )}
              {renderedText && <pre>{renderedText}</pre>}
            </div>
          ) : (
            <p className="muted">{t('emailBodyNotRecorded')}</p>
          )}
        </section>
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
  const visibleFacts = facts.filter(([, value]) => Boolean(value));

  return (
    <section className="detail-card">
      <div className="detail-card-title">
        <span>{icon}</span>
        <h3>{title}</h3>
      </div>
      {visibleFacts.length === 0 ? (
        <p className="muted">{emptyText}</p>
      ) : (
        <div className="fact-grid">
          {visibleFacts.map(([label, value]) => (
            <div key={label} className="fact-row">
              <span>{label}</span>
              <strong>{displayValue(value)}</strong>
            </div>
          ))}
        </div>
      )}
    </section>
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

function displayValue(value: unknown) {
  if (value === null || value === undefined || value === '') return '';
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

function dateTimeText(value: unknown) {
  const date =
    typeof value === 'string'
      ? new Date(value)
      : value && typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function'
        ? value.toDate()
        : null;
  if (!date || Number.isNaN(date.getTime())) return '';
  return date.toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

function humanizeToken(value: string) {
  return value
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (character) => character.toUpperCase());
}

function notificationEventLabel(t: (key: string, options?: Record<string, unknown>) => string, eventType?: string) {
  const fallback = humanizeToken(eventType || '');
  return t(`notificationEvent_${eventType || 'unknown'}`, { defaultValue: fallback || t('unknownEvent') });
}

function notificationStatusLabel(t: (key: string) => string, status?: string) {
  switch (status) {
    case 'sent':
      return t('notificationStatusSent');
    case 'failed':
      return t('notificationStatusFailed');
    case 'skipped':
      return t('notificationStatusSkipped');
    case 'suppressed':
      return t('notificationStatusSuppressed');
    case 'pending':
      return t('notificationStatusPending');
    default:
      return status ? humanizeToken(status) : t('unknown');
  }
}

function notificationStatusTone(status?: string) {
  switch (status) {
    case 'sent':
      return 'good';
    case 'failed':
      return 'danger';
    case 'skipped':
    case 'suppressed':
      return 'warning';
    case 'pending':
      return 'in_progress';
    default:
      return 'neutral';
  }
}
