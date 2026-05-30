import {
  GoogleAuthProvider,
  isSignInWithEmailLink,
  onAuthStateChanged,
  sendSignInLinkToEmail,
  signInWithEmailLink,
  signInWithPopup,
  signOut,
  type User,
} from 'firebase/auth';
import { auth } from './firebase';

const emailStorageKey = 'fiscore_admin_email_for_sign_in';

export function subscribeAuth(next: (user: User | null) => void) {
  return onAuthStateChanged(auth, next);
}

export async function signInWithGoogle() {
  await signInWithPopup(auth, new GoogleAuthProvider());
}

export async function sendEmailLink(email: string) {
  const cleanEmail = email.trim().toLowerCase();
  window.localStorage.setItem(emailStorageKey, cleanEmail);
  await sendSignInLinkToEmail(auth, cleanEmail, {
    url: window.location.origin,
    handleCodeInApp: true,
  });
}

export async function completeEmailLinkIfPresent() {
  if (!isSignInWithEmailLink(auth, window.location.href)) {
    return;
  }
  const email = window.localStorage.getItem(emailStorageKey) || window.prompt('Email address');
  if (!email) {
    return;
  }
  await signInWithEmailLink(auth, email, window.location.href);
  window.localStorage.removeItem(emailStorageKey);
  window.history.replaceState({}, document.title, window.location.origin);
}

export async function signOutUser() {
  await signOut(auth);
}
