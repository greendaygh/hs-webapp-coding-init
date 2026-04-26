import { type ReactNode } from 'react';
import { Navigate } from 'react-router-dom';

import { useAuth } from './useAuth';

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { status } = useAuth();
  if (status === 'loading') return <p>인증 확인 중…</p>;
  if (status === 'anonymous') return <Navigate to="/login" replace />;
  return <>{children}</>;
}
