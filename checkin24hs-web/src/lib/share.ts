/** Comparte una URL del pack (Web Share API o copia al portapapeles). */
export async function sharePackUrl(opts: {
  url: string;
  title: string;
  text?: string;
}): Promise<'shared' | 'copied' | 'cancelled'> {
  const { url, title, text } = opts;
  try {
    if (typeof navigator !== 'undefined' && typeof navigator.share === 'function') {
      await navigator.share({
        title,
        text: text || title,
        url,
      });
      return 'shared';
    }
  } catch (err) {
    if (err && typeof err === 'object' && 'name' in err && (err as { name: string }).name === 'AbortError') {
      return 'cancelled';
    }
  }

  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(url);
      return 'copied';
    }
  } catch {
    /* ignore */
  }

  window.prompt('Copiá el link del pack:', url);
  return 'copied';
}

export function absolutePackUrl(path: string): string {
  if (typeof window === 'undefined') return path;
  try {
    return new URL(path, window.location.origin).toString();
  } catch {
    return `${window.location.origin}${path.startsWith('/') ? path : `/${path}`}`;
  }
}
