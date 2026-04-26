import { Navigate } from 'react-router-dom';

import { LoginButton } from './LoginButton';
import { useAuth } from './useAuth';

export function LoginPage() {
  const { status } = useAuth();
  if (status === 'authenticated') return <Navigate to="/" replace />;

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui, sans-serif', maxWidth: 480, margin: '0 auto' }}>
      <h1>로그인</h1>
      <p>OIDC 공급자를 선택해 로그인하세요.</p>
      <LoginButton />
    </main>
  );
}
