import { apiClient } from '@/lib/apiClient';

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  provider: string;
  roles: string[];
}

export interface ProvidersResponse {
  providers: string[];
}

const AUTH_PREFIX = '{{api_v1_prefix}}/auth';

export async function getMe(): Promise<AuthUser | null> {
  try {
    const res = await apiClient.get<AuthUser>(`${AUTH_PREFIX}/me`);
    return res.data;
  } catch (err: unknown) {
    const status = (err as { response?: { status?: number } }).response?.status;
    if (status === 401) return null;
    throw err;
  }
}

export async function getProviders(): Promise<string[]> {
  const res = await apiClient.get<ProvidersResponse>(`${AUTH_PREFIX}/providers`);
  return res.data.providers ?? [];
}

export async function logout(): Promise<void> {
  await apiClient.post(`${AUTH_PREFIX}/logout`);
}

export function loginUrl(provider: string): string {
  return `${AUTH_PREFIX}/login/${provider}`;
}

export function mockLoginUrl(email: string): string {
  return `${AUTH_PREFIX}/login/mock?email=${encodeURIComponent(email)}`;
}
