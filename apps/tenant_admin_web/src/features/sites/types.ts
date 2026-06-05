export type Site = {
  id: string;
  name?: string;
  addressLine1?: string;
  city?: string;
  state?: string;
  stateCode?: string;
  postalCode?: string;
  zipCode?: string;
  phone?: string;
  siteType?: string;
  status?: string;
  linkStatus?: string;
  linkMethod?: string;
  masterRestaurantId?: string | null;
  manuallyCreated?: boolean;
  inspectionCountSnapshot?: number;
  latestInspectionDateSnapshot?: string;
  latestInspectionGradeSnapshot?: string;
  latestInspectionScoreSnapshot?: number;
  openViolationCountSnapshot?: number;
  pendingReviewCountSnapshot?: number;
  unassignedActiveViolationCountSnapshot?: number;
};

export type RestaurantSearchResult = {
  masterRestaurantId: string;
  displayName?: string;
  addressLine1?: string;
  city?: string;
  stateCode?: string;
  zipCode?: string;
  inspectionCount?: number;
  latestInspectionDate?: string;
};
