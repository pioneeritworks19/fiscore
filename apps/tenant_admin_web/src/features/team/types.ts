import type { Role } from '../../shared/types/core';

export type Member = {
  id: string;
  userId?: string;
  displayNameSnapshot?: string;
  emailSnapshot?: string;
  role?: Role;
  status?: string;
  siteAccessMode?: 'all' | 'selected';
  siteIds?: string[];
};

export type Invite = {
  id: string;
  email?: string;
  role?: Role;
  status?: string;
  siteAccessMode?: 'all' | 'selected';
  siteIds?: string[];
};
