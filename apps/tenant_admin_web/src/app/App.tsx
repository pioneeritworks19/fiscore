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
  ChevronDown,
  CheckCircle2,
  ClipboardCheck,
  CreditCard,
  FileText,
  Globe2,
  GraduationCap,
  LayoutDashboard,
  LifeBuoy,
  LogOut,
  Mail,
  Menu,
  MessageSquare,
  PlayCircle,
  PlusCircle,
  Settings,
  ShieldCheck,
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
  createTenantAndOwner,
  subscribeActivity,
  subscribeInvites,
  subscribeMember,
  subscribeMembers,
  subscribeSites,
  subscribeTenant,
  subscribeTrainingAssignments,
  subscribeUserProfile,
  updateLanguagePreference,
} from '../data';
import type {
  Activity as ActivityItem,
  Invite,
  Member,
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
import { AddSiteScreen, SiteRow, SitesPage } from '../features/sites/SitesPage';
import { TeamPage } from '../features/team/TeamPage';
import { AuditsPage, PublicInspectionsPage } from '../features/audits/AuditsPage';
import i18n from '../shared/i18n/i18n';

const tenantAdminRoles = ['tenant_owner', 'admin'];

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
