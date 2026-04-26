import { useQuery } from '@tanstack/react-query';
import { Route, Routes } from 'react-router-dom';

import { AuthProvider, LoginPage, ProtectedRoute, UserMenu } from '@/features/auth';
import { apiClient } from '@/lib/apiClient';

function HealthSection() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['health'],
    queryFn: async () => {
      const res = await apiClient.get<{ status: string; env: string }>('{{health_endpoint}}');
      return res.data;
    },
  });
  return (
    <section>
      <h2>Backend health</h2>
      {isLoading && <p>loading…</p>}
      {error && <p style={{ color: 'crimson' }}>error: {(error as Error).message}</p>}
      {data && (
        <ul>
          <li>status: {data.status}</li>
          <li>env: {data.env}</li>
        </ul>
      )}
    </section>
  );
}

function Home() {
  return (
    <main style={{ padding: 24, fontFamily: 'system-ui, sans-serif' }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1>{{project_name}}</h1>
        <UserMenu />
      </header>
      <p>{{description}}</p>
      <HealthSection />
    </main>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <Home />
            </ProtectedRoute>
          }
        />
      </Routes>
    </AuthProvider>
  );
}
