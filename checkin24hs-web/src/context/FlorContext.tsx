import { createContext, useContext, useState, ReactNode } from 'react';
import type { FlorContext as FlorContextType } from '../components/FlorWidget';

const ctx = createContext<{
  context: FlorContextType | undefined;
  setContext: (c: FlorContextType | undefined) => void;
}>({ context: undefined, setContext: () => {} });

export function FlorProvider({ children }: { children: ReactNode }) {
  const [context, setContext] = useState<FlorContextType | undefined>(undefined);
  return (
    <ctx.Provider value={{ context, setContext }}>
      {children}
    </ctx.Provider>
  );
}

export function useFlorContext() {
  return useContext(ctx);
}
