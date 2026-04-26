import { http, HttpResponse } from 'msw';
import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import { server } from '@/mocks/server';

import { LoginButton } from '../LoginButton';

describe('LoginButton', () => {
  it('lists active providers from /auth/providers', async () => {
    server.use(
      http.get(/\/auth\/providers$/, () => HttpResponse.json({ providers: ['google', 'mock'] })),
    );
    render(<LoginButton />);
    await waitFor(() => expect(screen.getByText(/Google 로 로그인/i)).toBeInTheDocument());
    expect(screen.getByText(/Mock 로그인/i)).toBeInTheDocument();
  });

  it('shows empty message when no providers', async () => {
    server.use(http.get(/\/auth\/providers$/, () => HttpResponse.json({ providers: [] })));
    render(<LoginButton />);
    await waitFor(() => expect(screen.getByText(/활성 공급자가 없습니다/)).toBeInTheDocument());
  });
});
