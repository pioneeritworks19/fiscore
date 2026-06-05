export type Tenant = {
  id: string;
  name?: string;
  status?: string;
  primaryOwnerUserId?: string;
  subscriptionStatus?: string;
  billingProvider?: string;
  includedSiteCount?: number;
  activeSiteCount?: number;
};
