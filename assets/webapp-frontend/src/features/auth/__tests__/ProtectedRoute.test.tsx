import { http, HttpResponse } from 'msw';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, expect, it } from 'vitest';

import { server } from '@/mocks/server';

import { AuthProvider } from '../AuthContext';
import { ProtectedRoute } from '../ProtectedRoute';

function renderApp(initialEntries: string[]) {
  return render(
    <AuthProvider>
      <MemoryRouter initialEntries={initialEntries}>
        <Routes>
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <div>SECRET PAGE</div>
              </ProtectedRoute>
            }
          />
          <Route path="/login" element={<div>LOGIN PAGE</div>} />
        </Routes>
      </MemoryRouter>
    </AuthProvider>,
  );
}

describe('ProtectedRoute', () => {
  it('redirects to /login when anonymous', async () => {
    server.use(http.get(/\/auth\/me$/, () => new HttpResponse(null, { status: 401 })));
    renderApp(['/']);
    await waitFor(() => expect(screen.getByText(/login page/i)).toBeInTheDocument());
  });

  it('renders children when authenticated', async () => {
    server.use(
      http.get(/\/auth\/me$/, () =>
        HttpResponse.json({ id: 'u1', email: 'a@b.c', name: 'A', provider: 'mock', roles: [] }),
      ),
    );
    renderApp(['/']);
    await waitFor(() => expect(screen.getByText(/secret page/i)).toBeInTheDocument());
  });
});
