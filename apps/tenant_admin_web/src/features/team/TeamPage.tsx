import { useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { Building2, LifeBuoy, Mail, UserPlus, Users, X } from 'lucide-react';
import {
  cancelTenantInvite,
  createTenantInvite,
  deactivateTenantMember,
  updateTenantMemberAccess,
} from './service';
import type { Invite, Member } from './types';
import type { Role } from '../../shared/types/core';
import type { Site } from '../sites/types';

const roles: Role[] = ['admin', 'manager', 'auditor', 'staff'];

export function TeamPage({ tenantId, sites, members, invites }: { tenantId: string; sites: Site[]; members: Member[]; invites: Invite[] }) {
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
  eyebrow,
}: {
  icon: ReactNode;
  title: string;
  body: string;
  action?: string;
  onAction?: () => void;
  eyebrow?: string;
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      {eyebrow && <span>{eyebrow}</span>}
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

function Field({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="field">
      <span>{label}</span>
      <input value={value} onChange={(event) => onChange(event.target.value)} />
    </label>
  );
}
