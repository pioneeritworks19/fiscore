import { useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertTriangle, Building2, Edit3, MapPin, Search, Trash2, X } from 'lucide-react';
import { friendlyError, type FriendlyError } from '../../shared/utils/errors';
import {
  createSite,
  deleteSite,
  linkMasterRestaurantSite,
  searchMasterRestaurants,
  updateManualSite,
} from './service';
import type { RestaurantSearchResult, Site } from './types';

const states = [
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
  'DC',
];

export function SitesPage({
  tenantId,
  sites,
  requestAddSite,
}: {
  tenantId: string;
  sites: Site[];
  requestAddSite: () => void;
}) {
  const { t } = useTranslation();

  return (
    <div className="page-stack">
      <section className="page-intro">
        <div>
          <p className="eyebrow">{t('siteDirectory')}</p>
          <h2>{t('sitesHeadline')}</h2>
          <p>{t('sitesIntro')}</p>
        </div>
        <button className="button primary" onClick={requestAddSite}>
          <Building2 size={18} />
          {t('addSite')}
        </button>
      </section>
      <section className="panel">
        <SectionTitle title={t('sites')} subtitle={t('sitesListHelp')} />
        <div className="table-list">
          {sites.map((site) => (
            <SiteRow key={site.id} tenantId={tenantId} site={site} allowActions />
          ))}
          {sites.length === 0 && (
            <EmptyState
              icon={<MapPin size={22} />}
              title={t('emptySitesTitle')}
              body={t('emptySitesBody')}
              action={t('addSite')}
              onAction={requestAddSite}
            />
          )}
        </div>
      </section>
    </div>
  );
}

export function SiteRow({
  tenantId,
  site,
  allowActions = false,
}: {
  tenantId?: string;
  site: Site;
  allowActions?: boolean;
}) {
  const { t } = useTranslation();
  const [editing, setEditing] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const manual = isManualSite(site);
  const address = siteAddress(site);

  return (
    <div className="site-row">
      <div className="row-icon">
        <Building2 size={18} />
      </div>
      <div className="site-main">
        <strong>{site.name}</strong>
        <p>{address || t('unlinked')}</p>
        <span className={manual ? 'source-badge manual' : 'source-badge linked'}>
          {manual ? t('manualSite') : t('linkedPublicRecord')}
        </span>
      </div>
      <div className="site-stats">
        <span>{t('inspections', { count: site.inspectionCountSnapshot || 0 })}</span>
        <span>{site.latestInspectionDateSnapshot || t('latestInspection')}</span>
        <span>{site.openViolationCountSnapshot || 0} {t('openViolations').toLowerCase()}</span>
      </div>
      {allowActions && tenantId && (
        <div className="site-actions" aria-label={t('siteActions')}>
          {manual && (
            <button className="icon-button" onClick={() => setEditing(true)} title={t('editSite')}>
              <Edit3 size={17} />
            </button>
          )}
          <button className="icon-button danger" onClick={() => setDeleting(true)} title={t('deleteSite')}>
            <Trash2 size={17} />
          </button>
        </div>
      )}
      {editing && tenantId && (
        <EditManualSiteDialog
          tenantId={tenantId}
          site={site}
          onClose={() => setEditing(false)}
        />
      )}
      {deleting && tenantId && (
        <DeleteSiteDialog
          tenantId={tenantId}
          site={site}
          onClose={() => setDeleting(false)}
        />
      )}
    </div>
  );
}

function EditManualSiteDialog({
  tenantId,
  site,
  onClose,
}: {
  tenantId: string;
  site: Site;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<FriendlyError | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [draft, setDraft] = useState({
    siteName: site.name || '',
    addressLine1: site.addressLine1 || '',
    city: site.city || '',
    state: site.state || site.stateCode || 'NY',
    postalCode: site.postalCode || site.zipCode || '',
  });

  function validate() {
    const nextErrors: Record<string, string> = {};
    if (!draft.siteName.trim()) nextErrors.siteName = t('restaurantNameRequired');
    if (!draft.addressLine1.trim()) nextErrors.addressLine1 = t('streetAddressRequired');
    if (!draft.city.trim()) nextErrors.city = t('cityRequired');
    if (!draft.postalCode.trim()) nextErrors.postalCode = t('zipRequired');
    setFieldErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      setError({ title: t('manualValidationTitle'), body: t('manualValidationBody') });
      return false;
    }
    setError(null);
    return true;
  }

  async function save() {
    if (!validate()) return;
    setBusy(true);
    try {
      await updateManualSite(tenantId, site.id, draft);
      onClose();
    } catch (err) {
      setError(friendlyError(err, {
        title: t('updateSiteFailedTitle'),
        body: t('updateSiteFailedBody'),
      }));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Dialog title={t('editSite')} onClose={onClose}>
      <p className="dialog-copy">{t('editManualSiteHelp')}</p>
      <div className="manual-grid">
        <Field required error={fieldErrors.siteName} label={t('restaurantName')} value={draft.siteName} onChange={(siteName) => {
          setDraft({ ...draft, siteName });
          setFieldErrors(({ siteName: _siteName, ...rest }) => rest);
        }} />
        <Field required error={fieldErrors.addressLine1} label={t('streetAddress')} value={draft.addressLine1} onChange={(addressLine1) => {
          setDraft({ ...draft, addressLine1 });
          setFieldErrors(({ addressLine1: _addressLine1, ...rest }) => rest);
        }} />
        <Field required error={fieldErrors.city} label={t('city')} value={draft.city} onChange={(city) => {
          setDraft({ ...draft, city });
          setFieldErrors(({ city: _city, ...rest }) => rest);
        }} />
        <label className="field">
          <span>{t('state')}</span>
          <select value={draft.state} onChange={(event) => setDraft({ ...draft, state: event.target.value })}>
            {states.map((stateCode) => (
              <option key={stateCode} value={stateCode}>{stateCode}</option>
            ))}
          </select>
        </label>
        <Field required error={fieldErrors.postalCode} label={t('zip')} value={draft.postalCode} onChange={(postalCode) => {
          setDraft({ ...draft, postalCode });
          setFieldErrors(({ postalCode: _postalCode, ...rest }) => rest);
        }} />
      </div>
      <div className="form-actions dialog-actions">
        <button className="button primary" onClick={() => void save()} disabled={busy}>
          {busy ? t('saving') : t('save')}
        </button>
        <button className="button secondary" onClick={onClose} disabled={busy}>
          {t('cancel')}
        </button>
      </div>
      {error && <ErrorNotice error={error} />}
    </Dialog>
  );
}

function DeleteSiteDialog({
  tenantId,
  site,
  onClose,
}: {
  tenantId: string;
  site: Site;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const [confirmation, setConfirmation] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<FriendlyError | null>(null);
  const canDelete = confirmation === 'DELETE';

  async function confirmDelete() {
    if (!canDelete) return;
    setBusy(true);
    setError(null);
    try {
      await deleteSite(tenantId, site.id, confirmation);
      onClose();
    } catch (err) {
      setError(friendlyError(err, {
        title: t('deleteSiteFailedTitle'),
        body: t('deleteSiteFailedBody'),
      }));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Dialog title={t('deleteSite')} onClose={onClose} danger>
      <div className="delete-summary">
        <AlertTriangle size={20} />
        <div>
          <strong>{t('deleteSiteWarningTitle', { name: site.name })}</strong>
          <p>{t('deleteSiteWarningBody')}</p>
        </div>
      </div>
      <div className="review-site compact-review">
        <div className="row-icon">
          <Building2 size={18} />
        </div>
        <div>
          <strong>{site.name}</strong>
          <p>{siteAddress(site)}</p>
        </div>
      </div>
      <label className="field">
        <span>{t('typeDeleteToConfirm')}</span>
        <input
          value={confirmation}
          onChange={(event) => setConfirmation(event.target.value)}
          autoComplete="off"
        />
      </label>
      <div className="form-actions dialog-actions">
        <button className="button danger-primary" onClick={() => void confirmDelete()} disabled={!canDelete || busy}>
          {busy ? t('deleting') : t('deletePermanently')}
        </button>
        <button className="button secondary" onClick={onClose} disabled={busy}>
          {t('cancel')}
        </button>
      </div>
      {error && <ErrorNotice error={error} />}
    </Dialog>
  );
}

function Dialog({
  title,
  children,
  onClose,
  danger = false,
}: {
  title: string;
  children: ReactNode;
  onClose: () => void;
  danger?: boolean;
}) {
  return (
    <div className="dialog-backdrop" role="presentation">
      <section className={danger ? 'dialog danger-dialog' : 'dialog'} role="dialog" aria-modal="true" aria-label={title}>
        <div className="dialog-header">
          <h2>{title}</h2>
          <button className="icon-button" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>
        {children}
      </section>
    </div>
  );
}

export function AddSiteScreen({ tenantId, onDone }: { tenantId: string; onDone: () => void }) {
  const { t } = useTranslation();
  const [mode, setMode] = useState<'search' | 'manual'>('search');
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<RestaurantSearchResult[]>([]);
  const [hasSearched, setHasSearched] = useState(false);
  const [selectedResult, setSelectedResult] = useState<RestaurantSearchResult | null>(null);
  const [reviewManual, setReviewManual] = useState(false);
  const [busy, setBusy] = useState(false);
  const [linkingId, setLinkingId] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<FriendlyError | null>(null);
  const [manualErrors, setManualErrors] = useState<Record<string, string>>({});
  const [manual, setManual] = useState({ siteName: '', addressLine1: '', city: '', state: 'NY', postalCode: '' });

  function clearTransientState() {
    setError(null);
    setMessage(null);
    setManualErrors({});
  }

  function goToSearch() {
    setMode('search');
    setReviewManual(false);
    setSelectedResult(null);
    clearTransientState();
  }

  function goToManual() {
    setMode('manual');
    setReviewManual(false);
    setSelectedResult(null);
    clearTransientState();
  }

  async function onSearch() {
    if (query.trim().length < 2) return;
    setBusy(true);
    setError(null);
    setMessage(null);
    setHasSearched(false);
    try {
      const response = await searchMasterRestaurants(tenantId, query);
      setResults(response.restaurants || []);
      setHasSearched(true);
    } catch (err) {
      setError(friendlyError(err, {
        title: t('searchFailedTitle'),
        body: t('searchFailedBody'),
      }));
      setHasSearched(true);
    } finally {
      setBusy(false);
    }
  }

  async function onLink(result: RestaurantSearchResult) {
    setLinkingId(result.masterRestaurantId);
    setError(null);
    try {
      await linkMasterRestaurantSite(tenantId, result.masterRestaurantId);
      onDone();
    } catch (err) {
      setError(friendlyError(err, {
        title: t('linkSiteFailedTitle'),
        body: t('linkSiteFailedBody'),
      }));
    } finally {
      setLinkingId(null);
    }
  }

  function onManualReview() {
    setError(null);
    const nextErrors: Record<string, string> = {};
    if (!manual.siteName.trim()) nextErrors.siteName = t('restaurantNameRequired');
    if (!manual.addressLine1.trim()) nextErrors.addressLine1 = t('streetAddressRequired');
    if (!manual.city.trim()) nextErrors.city = t('cityRequired');
    if (!manual.postalCode.trim()) nextErrors.postalCode = t('zipRequired');
    setManualErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      setError({
        title: t('manualValidationTitle'),
        body: t('manualValidationBody'),
      });
      return;
    }
    setReviewManual(true);
  }

  async function onManualSave() {
    setBusy(true);
    setError(null);
    try {
      await createSite(tenantId, manual);
      onDone();
    } catch (err) {
      setError(friendlyError(err, {
        title: t('createSiteFailedTitle'),
        body: t('createSiteFailedBody'),
      }));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page-stack add-site-page">
      <section className="wizard-header">
        <div>
          <p className="eyebrow">{t('addSiteFlow')}</p>
          <h2>{t('addSiteHeadline')}</h2>
          <p>{t('addSiteIntro')}</p>
        </div>
        <button className="button secondary" onClick={onDone}>
          {t('backToSites')}
        </button>
      </section>
      <section className="add-workflow panel">
            {selectedResult ? (
              <ReviewSiteCard
                title={t('confirmLinkedSiteTitle')}
                body={t('confirmLinkedSiteBody')}
                name={selectedResult.displayName || ''}
                address={formatRestaurantAddress(selectedResult)}
                meta={t('inspections', { count: selectedResult.inspectionCount || 0 })}
                primaryLabel={linkingId ? t('linking') : t('linkAndImport')}
                busy={Boolean(linkingId)}
                onPrimary={() => void onLink(selectedResult)}
                onBack={() => {
                  setSelectedResult(null);
                  clearTransientState();
                }}
              />
            ) : reviewManual ? (
              <ReviewSiteCard
                title={t('confirmManualSiteTitle')}
                body={t('confirmManualSiteBody')}
                name={manual.siteName}
                address={[manual.addressLine1, [manual.city, manual.state, manual.postalCode].filter(Boolean).join(' ')].filter(Boolean).join(', ')}
                meta={t('manualSite')}
                primaryLabel={busy ? t('saving') : t('createSite')}
                busy={busy}
                onPrimary={() => void onManualSave()}
                onBack={() => {
                  setReviewManual(false);
                  clearTransientState();
                }}
              />
            ) : mode === 'search' ? (
              <div className="add-flow-body">
                <div className="flow-heading">
                  <SectionTitle title={t('searchPublicRecords')} subtitle={t('searchPublicRecordsHelp')} />
                  <button
                    className="button secondary"
                    onClick={goToManual}
                    type="button"
                  >
                    <Building2 size={18} />
                    {t('createManualSite')}
                  </button>
                </div>
          <div className="search-row">
            <label className="field grow">
              <span>{t('restaurantNameCityZip')}</span>
              <input
                value={query}
                placeholder={t('restaurantNameCityZip')}
                onChange={(event) => setQuery(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') void onSearch();
                }}
              />
            </label>
            <button className="button primary" onClick={onSearch} disabled={busy}>
              {busy ? <span className="spinner" aria-hidden="true" /> : <Search size={18} />}
              {busy ? t('searching') : t('search')}
            </button>
          </div>
          {busy && (
            <div className="inline-progress">
              <span className="spinner" aria-hidden="true" />
              {t('searchingPublicRecords')}
            </div>
          )}
          {!busy && hasSearched && results.length === 0 && (
            <EmptyState
              icon={<Search size={22} />}
              title={t('noMatchingRestaurants')}
              body={t('noMatchingRestaurantsHelp')}
              action={t('createManualSite')}
              onAction={goToManual}
            />
          )}
          {results.length > 0 && (
            <div className="results-header">
              <div>
                <h3>{t('searchResults')}</h3>
                <p>{t('searchResultsHelp')}</p>
              </div>
              <button className="link-button" onClick={goToManual} type="button">
                {t('cantFindRestaurant')}
              </button>
            </div>
          )}
          {results.map((result) => (
            <div key={result.masterRestaurantId} className="restaurant-result">
              <div className="row-icon">
                <Building2 size={18} />
              </div>
              <div>
                <strong>{result.displayName}</strong>
                <p>
                  {[result.addressLine1, [result.city, result.stateCode, result.zipCode].filter(Boolean).join(' ')]
                    .filter(Boolean)
                    .join(', ')}
                </p>
                <span>{t('inspections', { count: result.inspectionCount || 0 })}</span>
              </div>
              <button className="button secondary" onClick={() => setSelectedResult(result)} disabled={Boolean(linkingId)}>
                {t('review')}
              </button>
            </div>
          ))}
              </div>
            ) : (
              <div className="manual-grid add-flow-body">
                <div className="flow-heading full">
                  <SectionTitle title={t('manualSiteNoteTitle')} subtitle={t('manualSiteIntro')} />
                  <button
                    className="button secondary"
                    onClick={goToSearch}
                    type="button"
                  >
                    <Search size={18} />
                    {t('backToSearch')}
                  </button>
                </div>
          <div className="manual-note full">
            <Building2 size={18} />
            <div>
              <strong>{t('manualSiteNoImportTitle')}</strong>
              <p>{t('manualSiteNoImportBody')}</p>
            </div>
          </div>
          <Field required error={manualErrors.siteName} label={t('restaurantName')} value={manual.siteName} onChange={(siteName) => {
            setManual({ ...manual, siteName });
            setManualErrors(({ siteName: _siteName, ...rest }) => rest);
          }} />
          <Field required error={manualErrors.addressLine1} label={t('streetAddress')} value={manual.addressLine1} onChange={(addressLine1) => {
            setManual({ ...manual, addressLine1 });
            setManualErrors(({ addressLine1: _addressLine1, ...rest }) => rest);
          }} />
          <Field required error={manualErrors.city} label={t('city')} value={manual.city} onChange={(city) => {
            setManual({ ...manual, city });
            setManualErrors(({ city: _city, ...rest }) => rest);
          }} />
          <label className="field">
            <span>{t('state')}</span>
            <select value={manual.state} onChange={(event) => setManual({ ...manual, state: event.target.value })}>
              {states.map((stateCode) => (
                <option key={stateCode} value={stateCode}>
                  {stateCode}
                </option>
              ))}
            </select>
          </label>
          <Field required error={manualErrors.postalCode} label={t('zip')} value={manual.postalCode} onChange={(postalCode) => {
            setManual({ ...manual, postalCode });
            setManualErrors(({ postalCode: _postalCode, ...rest }) => rest);
          }} />
          <div className="form-actions full">
            <button className="button primary" onClick={onManualReview} disabled={busy}>
              {t('reviewSite')}
            </button>
            <button className="button secondary" onClick={goToSearch}>
              {t('cancel')}
            </button>
          </div>
              </div>
            )}
            {message && <div className="status success">{message}</div>}
            {error && <ErrorNotice error={error} />}
        </section>
    </div>
  );
}

function ReviewSiteCard({
  title,
  body,
  name,
  address,
  meta,
  primaryLabel,
  busy,
  onPrimary,
  onBack,
}: {
  title: string;
  body: string;
  name: string;
  address: string;
  meta: string;
  primaryLabel: string;
  busy: boolean;
  onPrimary: () => void;
  onBack: () => void;
}) {
  const { t } = useTranslation();
  return (
    <div className="review-card">
      <div className="review-header">
        <div>
          <h2>{title}</h2>
          <p>{body}</p>
        </div>
      </div>
      <div className="review-site">
        <div className="row-icon">
          <Building2 size={18} />
        </div>
        <div>
          <strong>{name}</strong>
          <p>{address}</p>
          <span>{meta}</span>
        </div>
      </div>
      <div className="form-actions">
        <button className="button secondary" onClick={onBack} disabled={busy}>
          {t('back')}
        </button>
        <button className="button primary" onClick={onPrimary} disabled={busy}>
          {busy && <span className="spinner" aria-hidden="true" />}
          {primaryLabel}
        </button>
      </div>
    </div>
  );
}

function ErrorNotice({ error }: { error: FriendlyError }) {
  return (
    <div className="error-notice" role="alert">
      <strong>{error.title}</strong>
      <p>{error.body}</p>
    </div>
  );
}

function formatRestaurantAddress(result: RestaurantSearchResult) {
  return [
    result.addressLine1,
    [result.city, result.stateCode, result.zipCode].filter(Boolean).join(' '),
  ]
    .filter(Boolean)
    .join(', ');
}

function siteAddress(site: Site) {
  return [
    site.addressLine1,
    [site.city, site.state || site.stateCode, site.postalCode || site.zipCode].filter(Boolean).join(' '),
  ]
    .filter(Boolean)
    .join(', ');
}

function isManualSite(site: Site) {
  return Boolean(
    site.manuallyCreated ||
      site.linkStatus === 'manual_unlinked' ||
      (!site.masterRestaurantId && site.linkStatus !== 'linked'),
  );
}

function initialsFor(value: string) {
  const parts = value
    .replace(/@.*/, '')
    .split(/[.\s_-]+/)
    .filter(Boolean);
  return (parts[0]?.[0] || 'F').toUpperCase() + (parts[1]?.[0] || '').toUpperCase();
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
  action,
  onAction,
}: {
  icon: ReactNode;
  title: string;
  body: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      <strong>{title}</strong>
      <p>{body}</p>
      {action && onAction && (
        <button className="button secondary" onClick={onAction}>
          {action}
        </button>
      )}
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  required = false,
  error,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  required?: boolean;
  error?: string;
}) {
  return (
    <label className={error ? 'field invalid' : 'field'}>
      <span>
        {label}
        {required ? ' *' : ''}
      </span>
      <input value={value} onChange={(event) => onChange(event.target.value)} />
      {error && <small>{error}</small>}
    </label>
  );
}
