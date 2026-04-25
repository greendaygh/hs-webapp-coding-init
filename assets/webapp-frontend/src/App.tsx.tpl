import { useQuery } from '@tanstack/react-query';

import { apiClient } from '@/lib/apiClient';

export default function App() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['health'],
    queryFn: async () => {
      const res = await apiClient.get<{ status: string; env: string }>('{{health_endpoint}}');
      return res.data;
    },
  });

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui, sans-serif' }}>
      <h1>{{project_name}}</h1>
      <p>{{description}}</p>
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
    </main>
  );
}
