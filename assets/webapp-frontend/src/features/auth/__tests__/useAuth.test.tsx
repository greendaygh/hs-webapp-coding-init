import { http, HttpResponse } from 'msw';
import { renderHook, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import { server } from '@/mocks/server';

import { AuthProvider } from '../AuthContext';
import { useAuth } from '../useAuth';

function wrapper({ children }: { children: React.ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>;
}

describe('useAuth', () => {
  it('starts in loading and resolves to anonymous on 401', async () => {
    server.use(
      http.get(/\/auth\/me$/, () => new HttpResponse(null, { status: 401 })),
    );
    const { result } = renderHook(() => useAuth(), { wrapper });
    expect(result.current.status).toBe('loading');
    await waitFor(() => expect(result.current.status).toBe('anonymous'));
    expect(result.current.user).toBeNull();
  });

  it('resolves to authenticated when /auth/me returns user', async () => {
    server.use(
      http.get(/\/auth\/me$/, () =>
        HttpResponse.json({
          id: 'u1',
          email: 'a@b.c',
          name: 'A',
          provider: 'mock',
          roles: [],
        }),
      ),
    );
    const { result } = renderHook(() => useAuth(), { wrapper });
    await waitFor(() => expect(result.current.status).toBe('authenticated'));
    expect(result.current.user?.email).toBe('a@b.c');
  });
});
