import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { MemoryRouter } from 'react-router-dom';
import { describe, expect, it } from 'vitest';

import { server } from './mocks/server';

import App from './App';

function renderWithProviders(ui: React.ReactNode, initialEntries: string[] = ['/']) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <MemoryRouter initialEntries={initialEntries}>{ui}</MemoryRouter>
    </QueryClientProvider>,
  );
}

describe('App', () => {
  it('redirects anonymous users to /login', async () => {
    server.use(http.get(/\/auth\/me$/, () => new HttpResponse(null, { status: 401 })));
    renderWithProviders(<App />);
    await waitFor(() => expect(screen.getByRole('heading', { name: /로그인/ })).toBeInTheDocument());
  });

  it('renders project name and health when authenticated', async () => {
    server.use(
      http.get(/\/auth\/me$/, () =>
        HttpResponse.json({ id: 'u1', email: 'a@b.c', name: 'A', provider: 'mock', roles: [] }),
      ),
    );
    renderWithProviders(<App />);
    await waitFor(() => expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument());
    await waitFor(() => expect(screen.getByText(/status: ok/i)).toBeInTheDocument());
  });
});
