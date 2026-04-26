import { useEffect, useState } from 'react';

import { getProviders, loginUrl, mockLoginUrl } from './api';

export function LoginButton() {
  const [providers, setProviders] = useState<string[] | null>(null);
  const [mockEmail, setMockEmail] = useState('tester@example.com');

  useEffect(() => {
    getProviders()
      .then(setProviders)
      .catch(() => setProviders([]));
  }, []);

  if (providers === null) return <p>로그인 공급자 조회 중…</p>;
  if (providers.length === 0) return <p>활성 공급자가 없습니다. 환경 변수를 확인하세요.</p>;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {providers
        .filter((p) => p !== 'mock')
        .map((p) => (
          <a key={p} href={loginUrl(p)} style={btnStyle}>
            {labelFor(p)} 로 로그인
          </a>
        ))}
      {providers.includes('mock') && (
        <form
          method="get"
          action="."
          onSubmit={(e) => {
            e.preventDefault();
            window.location.href = mockLoginUrl(mockEmail);
          }}
          style={{ display: 'flex', gap: 8, alignItems: 'center' }}
        >
          <input
            type="email"
            value={mockEmail}
            onChange={(e) => setMockEmail(e.target.value)}
            aria-label="mock email"
            style={{ padding: 6 }}
          />
          <button type="submit" style={btnStyle}>
            Mock 로그인 (dev)
          </button>
        </form>
      )}
    </div>
  );
}

const btnStyle: React.CSSProperties = {
  display: 'inline-block',
  padding: '8px 14px',
  background: '#1f2937',
  color: 'white',
  textDecoration: 'none',
  borderRadius: 6,
  border: 'none',
  cursor: 'pointer',
};

function labelFor(p: string): string {
  if (p === 'google') return 'Google';
  if (p === 'github') return 'GitHub';
  return p;
}
