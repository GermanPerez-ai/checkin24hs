import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import type { FlorContext as FlorContextType } from '../components/FlorWidget';
import { buildWhatsAppConsultaUrl } from '../config';

const DEFAULT_FLOATING_TEXT = 'Hola, tengo una consulta desde checkin24hs.com';

const ctx = createContext<{
  context: FlorContextType | undefined;
  setContext: (c: FlorContextType | undefined) => void;
}>({ context: undefined, setContext: () => {} });

export function FlorProvider({ children }: { children: ReactNode }) {
  const [context, setContext] = useState<FlorContextType | undefined>(undefined);

  useEffect(() => {
    const a = document.getElementById('whatsapp-floating-btn') as HTMLAnchorElement | null;
    if (!a) return;
    const name = context?.hotelName?.trim();
    const tipo = context?.kind === 'pack' ? 'pack' : 'hotel';
    a.href = name
      ? buildWhatsAppConsultaUrl(name, tipo)
      : buildWhatsAppConsultaUrl(DEFAULT_FLOATING_TEXT, 'general');
  }, [context]);

  return (
    <ctx.Provider value={{ context, setContext }}>
      {children}
    </ctx.Provider>
  );
}

export function useFlorContext() {
  return useContext(ctx);
}
