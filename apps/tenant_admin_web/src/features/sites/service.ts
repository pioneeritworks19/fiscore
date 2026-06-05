import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '../../shared/firebase/firebase';
import { documentTo } from '../../shared/firebase/firestore';
import { callFunction } from '../../shared/firebase/functions';
import type { RestaurantSearchResult, Site } from './types';

export function subscribeSites(
  tenantId: string,
  next: (sites: Site[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(collection(db, 'tenants', tenantId, 'sites'), where('status', '==', 'active')),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<Site>(docSnap))),
    (err) => error(err.message),
  );
}

export async function searchMasterRestaurants(tenantId: string, searchText: string) {
  return callFunction<{ restaurants: RestaurantSearchResult[] }>('searchMasterRestaurants', {
    tenantId,
    query: searchText,
  });
}

export async function linkMasterRestaurantSite(tenantId: string, masterRestaurantId: string) {
  return callFunction<{ siteId: string }>('linkMasterRestaurantSite', {
    tenantId,
    masterRestaurantId,
  });
}

export async function createSite(
  tenantId: string,
  site: {
    siteName: string;
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
  },
) {
  return callFunction<{ siteId: string }>('createSite', {
    tenantId,
    ...site,
    siteType: 'restaurant',
  });
}

export async function updateManualSite(
  tenantId: string,
  siteId: string,
  site: {
    siteName: string;
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
  },
) {
  return callFunction<{ siteId: string }>('updateManualSite', {
    tenantId,
    siteId,
    ...site,
    siteType: 'restaurant',
  });
}

export async function deleteSite(tenantId: string, siteId: string, confirmation: string) {
  return callFunction<{ tenantId: string; siteId: string }>('deleteSite', {
    tenantId,
    siteId,
    confirmation,
  });
}
