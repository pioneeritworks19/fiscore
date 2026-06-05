import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  BarChart3,
  Bell,
  Building2,
  Camera,
  ChevronDown,
  CheckCircle2,
  ClipboardCheck,
  CreditCard,
  Edit3,
  FileText,
  Globe2,
  GraduationCap,
  History,
  LayoutDashboard,
  LifeBuoy,
  LogOut,
  Mail,
  MapPin,
  Menu,
  MessageSquare,
  PlayCircle,
  PlusCircle,
  Search,
  Settings,
  ShieldCheck,
  Trash2,
  UserCircle,
  UserPlus,
  Users,
  X,
} from 'lucide-react';
import type { User } from 'firebase/auth';
import {
  completeEmailLinkIfPresent,
  sendEmailLink,
  signInWithGoogle,
  signOutUser,
  subscribeAuth,
} from '../features/auth/authService';
import {
  cancelTenantInvite,
  createSite,
  createTenantAndOwner,
  createTenantInvite,
  deleteSite,
  deactivateTenantMember,
  linkMasterRestaurantSite,
  searchMasterRestaurants,
  subscribeActivity,
  subscribeAuditResponses,
  subscribeAuditsForSites,
  subscribePublicInspectionsForSites,
  subscribeInvites,
  subscribeMember,
  subscribeMembers,
  subscribeSites,
  subscribeTenant,
  subscribeTrainingAssignments,
  subscribeUserProfile,
  subscribeViolationsForAudit,
  subscribeViolationsForInspection,
  getStorageDownloadUrl,
  updateLanguagePreference,
  updateManualSite,
  updateTenantMemberAccess,
} from '../data';
import type {
  Activity as ActivityItem,
  Audit,
  AuditResponse,
  Invite,
  Member,
  PublicInspection,
  RestaurantSearchResult,
  Role,
  Site,
  Tenant,
  TrainingAssignment,
  UserProfile,
  Violation,
} from '../types';
import { NotificationHistoryPage } from '../features/notifications/NotificationHistoryPage';
import { SettingsPage } from '../features/settings/SettingsPage';
import {
  ViolationDetailPage,
  ViolationListRow,
  ViolationsPage,
} from '../features/violations/ViolationsPage';
import i18n from '../shared/i18n/i18n';
import { friendlyError, type FriendlyError } from '../shared/utils/errors';

const tenantAdminRoles = ['tenant_owner', 'admin'];
const roles: Role[] = ['admin', 'manager', 'auditor', 'staff'];
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

type View =
  | 'overview'
  | 'sites'
  | 'addSite'
  | 'violations'
  | 'audits'
  | 'inspections'
  | 'training'
  | 'team'
  | 'notifications'
  | 'templates'
  | 'analytics'
  | 'settings'
  | 'billing';

type AppState = {
  user: User | null;
  profile: UserProfile | null;
  tenant: Tenant | null;
  member: Member | null;
  sites: Site[];
  members: Member[];
  invites: Invite[];
  activity: ActivityItem[];
  loading: boolean;
  error: string | null;
};

const initialState: AppState = {
  user: null,
  profile: null,
  tenant: null,
  member: null,
  sites: [],
  members: [],
  invites: [],
  activity: [],
  loading: true,
  error: null,
};

export function App() {
  const [state, setState] = useState(initialState);
  const [view, setView] = useState<View>('overview');
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    completeEmailLinkIfPresent().catch((error) =>
      setState((current) => ({ ...current, error: error.message })),
    );
    return subscribeAuth((user) => {
      setState({ ...initialState, user, loading: Boolean(user) });
    });
  }, []);

  useEffect(() => {
    if (!state.user) {
      setState((current) => ({ ...current, loading: false }));
      return;
    }
    return subscribeUserProfile(
      state.user.uid,
      (profile) => {
        setState((current) => ({ ...current, profile, loading: false }));
        if (profile?.languagePreference) {
          void i18n.changeLanguage(profile.languagePreference);
        }
      },
      (error) => setState((current) => ({ ...current, error, loading: false })),
    );
  }, [state.user]);

  useEffect(() => {
    const tenantId = state.profile?.activeTenantId;
    if (!state.user || !tenantId) {
      setState((current) => ({
        ...current,
        tenant: null,
        member: null,
        sites: [],
        members: [],
        invites: [],
        activity: [],
      }));
      return;
    }

    const fail = (error: string) => setState((current) => ({ ...current, error }));
    const unsubs = [
      subscribeTenant(tenantId, (tenant) => setState((current) => ({ ...current, tenant })), fail),
      subscribeMember(
        tenantId,
        state.user.uid,
        (member) => setState((current) => ({ ...current, member })),
        fail,
      ),
      subscribeSites(tenantId, (sites) => setState((current) => ({ ...current, sites })), fail),
      subscribeMembers(
        tenantId,
        (members) => setState((current) => ({ ...current, members })),
        fail,
      ),
      subscribeInvites(tenantId, (invites) => setState((current) => ({ ...current, invites })), fail),
      subscribeActivity(
        tenantId,
        (activity) => setState((current) => ({ ...current, activity })),
        fail,
      ),
    ];
    return () => unsubs.forEach((unsubscribe) => unsubscribe());
  }, [state.user, state.profile?.activeTenantId]);

  if (state.loading) {
    return <LoadingScreen />;
  }

  if (!state.user) {
    return <LoginScreen error={state.error} />;
  }

  if (!state.profile?.activeTenantId) {
    return <SetupScreen user={state.user} />;
  }

  if (!state.member) {
    return <LoadingScreen />;
  }

  if (!tenantAdminRoles.includes(state.member.role || '')) {
    return <AccessDenied user={state.user} />;
  }

  return (
    <AdminLayout
      state={state}
      view={view}
      setView={setView}
      requestAddSite={() => {
        setView('addSite');
      }}
      menuOpen={menuOpen}
      setMenuOpen={setMenuOpen}
    />
  );
}

function LoadingScreen() {
  const { t } = useTranslation();
  return <div className="center-screen">{t('loading')}</div>;
}

function LoginScreen({ error }: { error: string | null }) {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [emailMode, setEmailMode] = useState(false);
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  async function onGoogle() {
    setBusy(true);
    setLocalError(null);
    try {
      await signInWithGoogle();
    } catch (err) {
      setLocalError(err instanceof Error ? err.message : t('requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  async function onEmail() {
    if (!email.includes('@')) {
      setLocalError(t('requestFailed'));
      return;
    }
    setBusy(true);
    setLocalError(null);
    try {
      await sendEmailLink(email);
      setSent(true);
    } catch (err) {
      setLocalError(err instanceof Error ? err.message : t('requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="login-page">
      <section className="login-story">
        <LogoMark />
        <p className="eyebrow">{t('adminConsole')}</p>
        <h1>{t('loginHeadline')}</h1>
        <p className="story-copy">{t('loginIntro')}</p>
        <div className="feature-grid">
          <Feature icon={<Building2 />} text={t('loginFeatureSites')} />
          <Feature icon={<Users />} text={t('loginFeatureTeam')} />
          <Feature icon={<ShieldCheck />} text={t('loginFeatureStandards')} />
          <Feature icon={<CreditCard />} text={t('loginFeatureBilling')} />
        </div>
        <div className="mobile-note">{t('mobileOperations')}</div>
      </section>
      <section className="auth-panel">
        <LogoLockup />
        {!emailMode ? (
          <>
            <button className="button primary" onClick={onGoogle} disabled={busy}>
              <LogOut size={18} />
              {t('continueWithGoogle')}
            </button>
            <div className="divider">
              <span>{t('or')}</span>
            </div>
            <button className="button secondary" onClick={() => setEmailMode(true)} disabled={busy}>
              <Mail size={18} />
              {t('continueWithEmail')}
            </button>
          </>
        ) : sent ? (
          <div className="status success">
            <CheckCircle2 size={20} />
            <div>
              <strong>{t('checkYourEmail')}</strong>
              <p>{t('signInLinkSent', { email })}</p>
              <button className="link-button" onClick={() => setSent(false)}>
                {t('useDifferentEmail')}
              </button>
            </div>
          </div>
        ) : (
          <>
            <label className="field">
              <span>{t('emailAddress')}</span>
              <input
                value={email}
                placeholder={t('emailAddressHint')}
                onChange={(event) => setEmail(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') void onEmail();
                }}
              />
            </label>
            <button className="button primary" onClick={onEmail} disabled={busy}>
              <Mail size={18} />
              {t('sendSignInLink')}
            </button>
            <button className="link-button" onClick={() => setEmailMode(false)}>
              {t('cancel')}
            </button>
          </>
        )}
        {(localError || error) && <p className="error-text">{localError || error}</p>}
      </section>
    </main>
  );
}

function Feature({ icon, text }: { icon: ReactNode; text: string }) {
  return (
    <div className="feature">
      {icon}
      <span>{text}</span>
    </div>
  );
}

function SetupScreen({ user }: { user: User }) {
  const { t } = useTranslation();
  const [tenantName, setTenantName] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onCreate() {
    if (!tenantName.trim()) return;
    setBusy(true);
    setError(null);
    try {
      await createTenantAndOwner(tenantName, user.displayName);
    } catch (err) {
      setError(err instanceof Error ? err.message : t('requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="setup-page">
      <section className="setup-panel">
        <LogoLockup />
        <p className="eyebrow">{t('setupWorkspace')}</p>
        <h1>{t('setupWorkspace')}</h1>
        <p>{t('setupWorkspaceIntro')}</p>
        <label className="field">
          <span>{t('workspaceName')}</span>
          <input
            value={tenantName}
            placeholder={t('workspaceNameHint')}
            onChange={(event) => setTenantName(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter') void onCreate();
            }}
          />
        </label>
        <button className="button primary" onClick={onCreate} disabled={busy}>
          <Building2 size={18} />
          {t('createWorkspace')}
        </button>
        {error && <p className="error-text">{error}</p>}
        <button className="link-button" onClick={() => void signOutUser()}>
          {t('signOut')}
        </button>
      </section>
    </main>
  );
}

function AccessDenied({ user }: { user: User }) {
  const { t } = useTranslation();
  return (
    <main className="center-screen">
      <ShieldCheck size={32} />
      <h1>{t('accessDenied')}</h1>
      <p>{t('signedInAs', { email: user.email })}</p>
      <button className="button secondary" onClick={() => void signOutUser()}>
        {t('signOut')}
      </button>
    </main>
  );
}

function AdminLayout({
  state,
  view,
  setView,
  requestAddSite,
  menuOpen,
  setMenuOpen,
}: {
  state: AppState;
  view: View;
  setView: (view: View) => void;
  requestAddSite: () => void;
  menuOpen: boolean;
  setMenuOpen: (open: boolean) => void;
}) {
  const { t } = useTranslation();
  const [profileOpen, setProfileOpen] = useState(false);
  const [language, setLanguage] = useState<'en' | 'es'>(
    (state.profile?.languagePreference || i18n.language || 'en').startsWith('es') ? 'es' : 'en',
  );
  const displayName = state.user?.displayName || state.profile?.displayName || state.user?.email || '';
  const initials = initialsFor(displayName || 'FiScore user');

  async function saveProfileLanguage(nextLanguage: 'en' | 'es') {
    setLanguage(nextLanguage);
    await updateLanguagePreference(state.user!.uid, nextLanguage);
    await i18n.changeLanguage(nextLanguage);
  }

  const nav = [
    ['overview', LayoutDashboard, t('overview')],
    ['sites', Building2, t('sites')],
    ['violations', AlertTriangle, t('violations')],
    ['audits', ClipboardCheck, t('audits')],
    ['inspections', FileText, t('publicInspections')],
    ['training', GraduationCap, t('training')],
    ['team', Users, t('team')],
    ['notifications', Bell, t('notifications')],
    ['templates', ShieldCheck, t('templates')],
    ['analytics', BarChart3, t('analytics')],
    ['billing', CreditCard, t('billing')],
    ['settings', Settings, t('settings')],
  ] as const;
  const currentPageTitle = view === 'addSite' ? t('addSite') : nav.find(([id]) => id === view)?.[2];

  return (
    <div className="admin-app">
      <aside className={menuOpen ? 'sidebar open' : 'sidebar'}>
        <div className="sidebar-top">
          <LogoLockup />
          <button className="icon-button mobile-only" onClick={() => setMenuOpen(false)}>
            <X size={20} />
          </button>
        </div>
        <nav>
          {nav.map(([id, Icon, label]) => (
            <button
              key={id}
              className={view === id ? 'nav-item active' : 'nav-item'}
              onClick={() => {
                setView(id);
                setMenuOpen(false);
              }}
            >
              <Icon size={18} />
              {label}
            </button>
          ))}
        </nav>
      </aside>
      <main className="workspace">
        <header className="topbar">
          <div className="workspace-title">
            <button className="icon-button mobile-only" onClick={() => setMenuOpen(true)}>
              <Menu size={20} />
            </button>
            <div>
              <h1>{state.tenant?.name || t('workspaceName')}</h1>
            </div>
          </div>
          <div className="account-menu">
            <button
              className="avatar-button"
              onClick={() => setProfileOpen(!profileOpen)}
              aria-expanded={profileOpen}
              aria-label={t('profileMenu')}
            >
              <span>{initials}</span>
              <ChevronDown size={16} />
            </button>
            {profileOpen && (
              <div className="account-popover">
                <div className="account-summary">
                  <UserCircle size={22} />
                  <div>
                    <strong>{displayName || t('profile')}</strong>
                    <p>{state.user?.email}</p>
                  </div>
                </div>
                <label className="field compact-field">
                  <span>{t('language')}</span>
                  <select
                    value={language}
                    onChange={(event) => void saveProfileLanguage(event.target.value as 'en' | 'es')}
                  >
                    <option value="en">{t('english')}</option>
                    <option value="es">{t('spanish')}</option>
                  </select>
                </label>
                <button className="menu-action" onClick={() => void signOutUser()}>
                  <LogOut size={17} />
                  {t('signOut')}
                </button>
              </div>
            )}
          </div>
        </header>
        <div className="page-heading">
          <h2>{currentPageTitle}</h2>
        </div>
        {state.error && <div className="status error">{state.error}</div>}
        {view === 'overview' && (
          <Overview state={state} setView={setView} requestAddSite={requestAddSite} />
        )}
        {view === 'sites' && (
          <SitesPage
            tenantId={state.profile!.activeTenantId!}
            sites={state.sites}
            requestAddSite={requestAddSite}
          />
        )}
        {view === 'addSite' && (
          <AddSiteScreen
            tenantId={state.profile!.activeTenantId!}
            onDone={() => setView('sites')}
          />
        )}
        {view === 'violations' && (
          <ViolationsPage
            tenantId={state.profile!.activeTenantId!}
            sites={state.sites}
          />
        )}
        {view === 'audits' && (
          <AuditsPage
            tenantId={state.profile!.activeTenantId!}
            sites={state.sites}
          />
        )}
        {view === 'inspections' && (
          <PublicInspectionsPage
            tenantId={state.profile!.activeTenantId!}
            sites={state.sites}
          />
        )}
        {view === 'training' && (
          <TrainingPage
            tenantId={state.profile!.activeTenantId!}
            sites={state.sites}
          />
        )}
        {view === 'team' && (
          <TeamPage tenantId={state.profile!.activeTenantId!} sites={state.sites} members={state.members} invites={state.invites} />
        )}
        {view === 'notifications' && (
          <NotificationHistoryPage tenantId={state.profile!.activeTenantId!} />
        )}
        {view === 'settings' && <SettingsPage user={state.user!} profile={state.profile} />}
        {view === 'billing' && <Placeholder title={t('billing')} body={t('billingPlaceholder')} />}
        {view === 'templates' && <Placeholder title={t('templates')} body={t('templatesPlaceholder')} />}
        {view === 'analytics' && <Placeholder title={t('analytics')} body={t('analyticsPlaceholder')} />}
      </main>
    </div>
  );
}

function Overview({
  state,
  setView,
  requestAddSite,
}: {
  state: AppState;
  setView: (view: View) => void;
  requestAddSite: () => void;
}) {
  const { t } = useTranslation();
  const activeMembers = state.members.filter((member) => member.status === 'active');
  const openViolations = state.sites.reduce((sum, site) => sum + (site.openViolationCountSnapshot || 0), 0);
  const pendingReview = state.sites.reduce((sum, site) => sum + (site.pendingReviewCountSnapshot || 0), 0);
  const unassigned = state.sites.reduce(
    (sum, site) => sum + (site.unassignedActiveViolationCountSnapshot || 0),
    0,
  );
  const pendingInvites = state.invites.filter((invite) => invite.status === 'pending').length;

  return (
    <div className="page-stack">
      <section className="dashboard-hero">
        <div>
          <p className="eyebrow">{t('commandCenter')}</p>
          <h2>{t('dashboardHeadline')}</h2>
          <p>{t('dashboardIntro')}</p>
        </div>
        <div className="hero-actions">
          <button className="button primary" onClick={requestAddSite}>
            <PlusCircle size={18} />
            {t('addSite')}
          </button>
          <button className="button secondary" onClick={() => setView('team')}>
            <UserPlus size={18} />
            {t('inviteUser')}
          </button>
        </div>
      </section>
      <section className="metric-grid">
        <Metric
          icon={<Building2 size={18} />}
          label={t('activeSites')}
          value={state.sites.length}
          helper={t('activeSitesHelper')}
        />
        <Metric
          icon={<AlertTriangle size={18} />}
          label={t('openViolations')}
          value={openViolations}
          helper={t('openViolationsHelper', { count: unassigned })}
          tone={openViolations > 0 ? 'warning' : 'good'}
        />
        <Metric
          icon={<ClipboardCheck size={18} />}
          label={t('pendingReview')}
          value={pendingReview}
          helper={t('pendingReviewHelper')}
        />
        <Metric
          icon={<Users size={18} />}
          label={t('teamMembers')}
          value={activeMembers.length}
          helper={t('teamMembersHelper', { count: pendingInvites })}
        />
      </section>
      <section className="content-grid">
        <div className="panel">
          <SectionTitle title={t('sitePerformance')} subtitle={t('sitePerformanceHelp')} />
          <div className="table-list">
            {state.sites.slice(0, 6).map((site) => (
              <SiteRow key={site.id} site={site} />
            ))}
            {state.sites.length === 0 && (
              <EmptyState
                icon={<Building2 size={22} />}
                title={t('emptySitesTitle')}
                body={t('emptySitesBody')}
                action={t('addSite')}
                onAction={requestAddSite}
              />
            )}
          </div>
        </div>
        <div className="panel">
          <SectionTitle title={t('recentActivity')} subtitle={t('recentActivityHelp')} />
          <div className="activity-list">
            {state.activity.slice(0, 8).map((item) => (
              <div key={item.id} className="activity-item">
                <Activity size={16} />
                <div>
                  <strong>{item.action?.replaceAll('_', ' ')}</strong>
                  <p>{item.targetEmail || item.targetDisplayName || item.actorEmail}</p>
                </div>
              </div>
            ))}
            {state.activity.length === 0 && (
              <EmptyState
                icon={<Activity size={22} />}
                title={t('noRecentActivityTitle')}
                body={t('noRecentActivity')}
              />
            )}
          </div>
        </div>
      </section>
    </div>
  );
}

function Metric({
  icon,
  label,
  value,
  helper,
  tone = 'neutral',
}: {
  icon: ReactNode;
  label: string;
  value: number;
  helper: string;
  tone?: 'neutral' | 'good' | 'warning';
}) {
  return (
    <div className={`metric ${tone}`}>
      <div className="metric-top">
        <span>{label}</span>
        <div className="metric-icon">{icon}</div>
      </div>
      <strong>{value}</strong>
      <p>{helper}</p>
    </div>
  );
}

function SitesPage({
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

function SiteRow({
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

function AddSiteScreen({ tenantId, onDone }: { tenantId: string; onDone: () => void }) {
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

function StatusBadge({ status }: { status: string }) {
  const { t } = useTranslation();
  return <span className={`status-badge ${status}`}>{t(status)}</span>;
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

function AuditsPage({ tenantId, sites }: { tenantId: string; sites: Site[] }) {
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

function PublicInspectionsPage({ tenantId, sites }: { tenantId: string; sites: Site[] }) {
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

function TrainingPage({ tenantId, sites }: { tenantId: string; sites: Site[] }) {
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

function TeamPage({ tenantId, sites, members, invites }: { tenantId: string; sites: Site[]; members: Member[]; invites: Invite[] }) {
  const { t } = useTranslation();
  const [inviteOpen, setInviteOpen] = useState(false);
  const [memberToManage, setMemberToManage] = useState<Member | null>(null);
  const [memberToDeactivate, setMemberToDeactivate] = useState<Member | null>(null);
  const [inviteToCancel, setInviteToCancel] = useState<Invite | null>(null);
  const activeMembers = members.filter((member) => member.status === 'active');
  const pendingInvites = invites.filter((invite) => invite.status === 'pending');

  return (
    <div className="page-stack team-page">
      <section className="dashboard-hero">
        <div>
          <p className="eyebrow">{t('teamAccess')}</p>
          <h2>{t('teamHeadline')}</h2>
          <p>{t('teamIntro')}</p>
        </div>
        <div className="hero-actions">
          <button className="button primary" onClick={() => setInviteOpen(true)}>
            <UserPlus size={18} />
            {t('inviteUser')}
          </button>
        </div>
      </section>
      <section className="summary-strip" aria-label={t('teamAccess')}>
        <div>
          <Users size={17} />
          <strong>{activeMembers.length}</strong>
          <span>{t('activeMembers')}</span>
        </div>
        <div>
          <Mail size={17} />
          <strong>{pendingInvites.length}</strong>
          <span>{t('pendingInvites')}</span>
        </div>
        <div className="good">
          <Building2 size={17} />
          <strong>{sites.length}</strong>
          <span>{t('sites')}</span>
        </div>
      </section>
      <section className="content-grid">
        <div className="panel">
          <SectionTitle title={t('activeMembers')} subtitle={t('activeMembersHelp')} />
          <div className="directory-list">
            {activeMembers.map((member) => (
              <MemberRow
                key={member.id}
                member={member}
                onManage={() => setMemberToManage(member)}
                onDeactivate={() => setMemberToDeactivate(member)}
              />
            ))}
          </div>
          {activeMembers.length === 0 && (
            <EmptyState icon={<Users size={22} />} title={t('emptyMembersTitle')} body={t('emptyMembers')} />
          )}
        </div>
        <div className="panel">
          <SectionTitle title={t('pendingInvites')} subtitle={t('pendingInvitesHelp')} />
          <div className="directory-list">
            {pendingInvites.map((invite) => (
              <InviteRow key={invite.id} invite={invite} onCancel={() => setInviteToCancel(invite)} />
            ))}
          </div>
          {pendingInvites.length === 0 && (
            <EmptyState icon={<Mail size={22} />} title={t('emptyInvitesTitle')} body={t('emptyInvites')} />
          )}
        </div>
      </section>
      {inviteOpen && (
        <InviteUserDrawer tenantId={tenantId} sites={sites} onClose={() => setInviteOpen(false)} />
      )}
      {memberToManage && (
        <ManageAccessDrawer
          tenantId={tenantId}
          member={memberToManage}
          sites={sites}
          onClose={() => setMemberToManage(null)}
        />
      )}
      {memberToDeactivate && (
        <ConfirmDialog
          title={t('deactivateMemberTitle', { name: memberToDeactivate.displayNameSnapshot || memberToDeactivate.emailSnapshot })}
          body={t('deactivateMemberBody')}
          confirmLabel={t('deactivate')}
          onCancel={() => setMemberToDeactivate(null)}
          onConfirm={async () => {
            await deactivateTenantMember(tenantId, memberToDeactivate.id);
            setMemberToDeactivate(null);
          }}
        />
      )}
      {inviteToCancel && (
        <ConfirmDialog
          title={t('cancelInviteTitle', { email: inviteToCancel.email })}
          body={t('cancelInviteBody')}
          confirmLabel={t('cancelInvite')}
          onCancel={() => setInviteToCancel(null)}
          onConfirm={async () => {
            await cancelTenantInvite(tenantId, inviteToCancel.id);
            setInviteToCancel(null);
          }}
        />
      )}
    </div>
  );
}

function InviteUserDrawer({ tenantId, sites, onClose }: { tenantId: string; sites: Site[]; onClose: () => void }) {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<Role>('manager');
  const [siteAccessMode, setSiteAccessMode] = useState<'all' | 'selected'>('all');
  const [siteIds, setSiteIds] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function invite() {
    setBusy(true);
    setError(null);
    try {
      await createTenantInvite({ tenantId, email, role, siteAccessMode, siteIds });
      setEmail('');
      setSiteIds([]);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : t('requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Drawer title={t('inviteUser')} subtitle={t('inviteUserHelp')} onClose={onClose}>
      <div className="team-form drawer-form">
          <Field label={t('email')} value={email} onChange={setEmail} />
          <label className="field">
            <span>{t('role')}</span>
            <select value={role} onChange={(event) => setRole(event.target.value as Role)}>
              {roles.map((roleId) => (
                <option key={roleId} value={roleId}>
                  {t(roleId)}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>{t('siteAccess')}</span>
            <select value={siteAccessMode} onChange={(event) => setSiteAccessMode(event.target.value as 'all' | 'selected')}>
              <option value="all">{t('allSites')}</option>
              <option value="selected">{t('selectedSites')}</option>
            </select>
          </label>
          {siteAccessMode === 'selected' && <SiteChecklist sites={sites} selected={siteIds} onChange={setSiteIds} />}
          <button className="button primary" onClick={invite} disabled={busy}>
            <Mail size={18} />
            {t('sendInvite')}
          </button>
        </div>
        {error && <div className="status error">{error}</div>}
    </Drawer>
  );
}

function MemberRow({ member, onManage, onDeactivate }: { member: Member; onManage: () => void; onDeactivate: () => void }) {
  const { t } = useTranslation();
  const locked = member.role === 'tenant_owner';

  return (
    <div className="member-row">
      <div>
        <strong>{member.displayNameSnapshot || member.emailSnapshot}</strong>
        <p>{member.emailSnapshot} - {member.role ? t(member.role === 'tenant_owner' ? 'owner' : member.role) : ''}</p>
        <span className="muted">{member.siteAccessMode === 'selected' ? `${member.siteIds?.length || 0} ${t('sites').toLowerCase()}` : t('allSites')}</span>
      </div>
      <div className="member-actions">
        <button className="button secondary compact" onClick={onManage} disabled={locked}>
          {t('manageAccess')}
        </button>
        {!locked && (
          <button className="button secondary compact" onClick={onDeactivate}>
            {t('deactivate')}
          </button>
        )}
      </div>
    </div>
  );
}

function InviteRow({ invite, onCancel }: { invite: Invite; onCancel: () => void }) {
  const { t } = useTranslation();
  return (
    <div className="member-row">
      <div>
        <strong>{invite.email}</strong>
        <p>{invite.role ? t(invite.role) : ''} - {invite.siteAccessMode === 'selected' ? `${invite.siteIds?.length || 0} ${t('sites').toLowerCase()}` : t('allSites')}</p>
      </div>
      <div className="member-actions">
        <button className="button secondary compact" onClick={onCancel}>
          {t('cancelInvite')}
        </button>
      </div>
    </div>
  );
}

function ManageAccessDrawer({ tenantId, member, sites, onClose }: { tenantId: string; member: Member; sites: Site[]; onClose: () => void }) {
  const { t } = useTranslation();
  const [role, setRole] = useState<Role>((member.role || 'staff') as Role);
  const [siteAccessMode, setSiteAccessMode] = useState<'all' | 'selected'>(member.siteAccessMode || 'all');
  const [siteIds, setSiteIds] = useState<string[]>(member.siteIds || []);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function save() {
    setBusy(true);
    setError('');
    try {
      await updateTenantMemberAccess({
        tenantId,
        userId: member.id,
        role,
        siteAccessMode,
        siteIds,
      });
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : t('requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Drawer
      title={t('manageAccess')}
      subtitle={member.displayNameSnapshot || member.emailSnapshot || t('teamMember')}
      onClose={onClose}
    >
      <div className="team-form drawer-form">
        <label className="field full">
          <span>{t('role')}</span>
          <select value={role} onChange={(event) => setRole(event.target.value as Role)}>
            {roles.map((roleId) => (
              <option key={roleId} value={roleId}>{t(roleId)}</option>
            ))}
          </select>
        </label>
        <label className="field full">
          <span>{t('siteAccess')}</span>
          <select value={siteAccessMode} onChange={(event) => setSiteAccessMode(event.target.value as 'all' | 'selected')}>
            <option value="all">{t('allSites')}</option>
            <option value="selected">{t('selectedSites')}</option>
          </select>
        </label>
        {siteAccessMode === 'selected' && <SiteChecklist sites={sites} selected={siteIds} onChange={setSiteIds} />}
        <button className="button primary" onClick={save} disabled={busy}>
          {busy ? t('saving') : t('save')}
        </button>
      </div>
      {error && <div className="status error">{error}</div>}
    </Drawer>
  );
}

function Drawer({ title, subtitle, onClose, children }: { title: string; subtitle?: string; onClose: () => void; children: ReactNode }) {
  return (
    <div className="drawer-layer" role="dialog" aria-modal="true" aria-label={title}>
      <button className="drawer-backdrop" onClick={onClose} aria-label="Close" />
      <aside className="drawer-panel">
        <div className="drawer-header">
          <div>
            <h3>{title}</h3>
            {subtitle && <p>{subtitle}</p>}
          </div>
          <button className="icon-button" onClick={onClose} aria-label="Close">
            <X size={20} />
          </button>
        </div>
        {children}
      </aside>
    </div>
  );
}

function ConfirmDialog({ title, body, confirmLabel, onCancel, onConfirm }: { title: string; body: string; confirmLabel: string; onCancel: () => void; onConfirm: () => Promise<void> }) {
  const { t } = useTranslation();
  const [busy, setBusy] = useState(false);
  return (
    <div className="drawer-layer" role="dialog" aria-modal="true" aria-label={title}>
      <button className="drawer-backdrop" onClick={onCancel} aria-label={t('cancel')} />
      <section className="confirm-dialog">
        <h3>{title}</h3>
        <p>{body}</p>
        <div className="form-actions">
          <button className="button secondary" onClick={onCancel}>{t('cancel')}</button>
          <button
            className="button danger-primary"
            disabled={busy}
            onClick={async () => {
              setBusy(true);
              try {
                await onConfirm();
              } finally {
                setBusy(false);
              }
            }}
          >
            {confirmLabel}
          </button>
        </div>
      </section>
    </div>
  );
}

function SiteChecklist({ sites, selected, onChange }: { sites: Site[]; selected: string[]; onChange: (ids: string[]) => void }) {
  return (
    <div className="site-checklist">
      {sites.map((site) => (
        <label key={site.id}>
          <input
            type="checkbox"
            checked={selected.includes(site.id)}
            onChange={(event) => {
              onChange(event.target.checked ? [...selected, site.id] : selected.filter((id) => id !== site.id));
            }}
          />
          {site.name}
        </label>
      ))}
    </div>
  );
}

function Placeholder({ title, body }: { title: string; body: string }) {
  const { t } = useTranslation();
  return (
    <section className="panel narrow">
      <EmptyState icon={<LifeBuoy size={24} />} title={title} body={body} eyebrow={t('comingSoon')} />
    </section>
  );
}

function SectionTitle({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div className="section-title">
      <h2>{title}</h2>
      {subtitle && <p>{subtitle}</p>}
    </div>
  );
}

function EmptyState({
  icon,
  title,
  body,
  eyebrow,
  action,
  onAction,
}: {
  icon: ReactNode;
  title: string;
  body: string;
  eyebrow?: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      {eyebrow && <p className="eyebrow">{eyebrow}</p>}
      <h3>{title}</h3>
      <p>{body}</p>
      {action && onAction && (
        <button className="button secondary" onClick={onAction}>
          {action}
          <ArrowRight size={16} />
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
      <span>{label}{required ? ' *' : ''}</span>
      <input
        aria-invalid={Boolean(error)}
        required={required}
        value={value}
        onChange={(event) => onChange(event.target.value)}
      />
      {error && <small>{error}</small>}
    </label>
  );
}

function LogoMark() {
  return (
    <div className="logo-mark">
      <span>Fi</span>
    </div>
  );
}

function LogoLockup() {
  return (
    <div className="logo-lockup">
      <LogoMark />
      <div>
        <strong>FiScore</strong>
        <span>Admin</span>
      </div>
    </div>
  );
}
