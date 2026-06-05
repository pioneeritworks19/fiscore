import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase';

export async function callFunction<T>(
  name: string,
  data: Record<string, unknown>,
): Promise<T> {
  const callable = httpsCallable<Record<string, unknown>, T>(functions, name);
  const result = await callable(data);
  return result.data;
}
