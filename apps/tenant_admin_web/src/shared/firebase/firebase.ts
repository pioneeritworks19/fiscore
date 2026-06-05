import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: 'AIzaSyA2-yeih3KmQ_fV3UJATqzjRQml0uFaa_g',
  authDomain: 'fiscore-dev.firebaseapp.com',
  projectId: 'fiscore-dev',
  storageBucket: 'fiscore-dev.firebasestorage.app',
  messagingSenderId: '558552038453',
  appId: '1:558552038453:web:17f6ab2945d73e4072c57c',
};

export const firebaseApp = initializeApp(firebaseConfig);
export const auth = getAuth(firebaseApp);
export const db = getFirestore(firebaseApp);
export const functions = getFunctions(firebaseApp, 'us-central1');
export const storage = getStorage(firebaseApp);
