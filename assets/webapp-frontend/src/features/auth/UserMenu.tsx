import { useAuth } from './useAuth';

export function UserMenu() {
  const { user, status, logout } = useAuth();

  if (status === 'loading') return <span aria-label="auth-loading">…</span>;
  if (status === 'anonymous' || !user) {
    return (
      <a href="/login" style={{ textDecoration: 'underline' }}>
        로그인
      </a>
    );
  }
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
      <span aria-label="current-user">{user.email}</span>
      <button type="button" onClick={() => void logout()} style={{ cursor: 'pointer' }}>
        로그아웃
      </button>
    </div>
  );
}
