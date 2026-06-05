import { getDownloadURL, ref } from 'firebase/storage';
import { storage } from './firebase';

export async function getStorageDownloadUrl(storagePath: string) {
  return getDownloadURL(ref(storage, storagePath));
}
