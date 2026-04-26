import { http, HttpResponse } from 'msw';

let mockUser: { id: string; email: string; name: string; provider: string; roles: string[] } | null = null;

export const handlers = [
  http.get('{{health_endpoint}}', () =>
    HttpResponse.json({ status: 'ok', env: 'test' }),
  ),
  http.get('{{api_v1_prefix}}/auth/me', () => {
    if (!mockUser) return new HttpResponse(null, { status: 401 });
    return HttpResponse.json(mockUser);
  }),
  http.get('{{api_v1_prefix}}/auth/providers', () =>
    HttpResponse.json({ providers: [], mock_enabled: true }),
  ),
  http.post('{{api_v1_prefix}}/auth/logout', () => {
    mockUser = null;
    return HttpResponse.json({ ok: true });
  }),
  http.get('{{api_v1_prefix}}/auth/login/mock', ({ request }) => {
    const url = new URL(request.url);
    const email = url.searchParams.get('email') ?? 'mock@example.com';
    mockUser = {
      id: 'mock-user-id',
      email,
      name: email.split('@')[0],
      provider: 'mock',
      roles: [],
    };
    return HttpResponse.json({ ok: true, user: mockUser });
  }),
];

export function __setMockUser(u: typeof mockUser) {
  mockUser = u;
}
