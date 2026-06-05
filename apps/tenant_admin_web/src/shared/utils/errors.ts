export type FriendlyError = {
  title: string;
  body: string;
};

export function friendlyError(error: unknown, fallback: FriendlyError): FriendlyError {
  const message = error instanceof Error ? error.message : '';
  const lower = message.toLowerCase();

  if (lower.includes('already-exists') || lower.includes('already linked')) {
    return {
      title: 'This restaurant is already linked.',
      body: 'Check the site directory before adding it again.',
    };
  }

  if (lower.includes('permission-denied') || lower.includes('permission')) {
    return {
      title: 'You do not have permission to do that.',
      body: 'Ask the tenant owner to update your role or site access.',
    };
  }

  if (lower.includes('invalid-argument')) {
    return {
      title: 'Some information needs attention.',
      body: 'Review the highlighted fields and try again.',
    };
  }

  if (lower.includes('not-found')) {
    return {
      title: 'We could not find that record.',
      body: 'Try searching again or create a manual site.',
    };
  }

  if (lower.includes('network') || lower.includes('unavailable') || lower.includes('failed')) {
    return {
      title: 'We could not complete the request.',
      body: 'Check your connection and try again.',
    };
  }

  return fallback;
}
