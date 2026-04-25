import { Page, request } from '@playwright/test';

/**
 * 로그인 헬퍼 (구현 예시).
 * 백엔드 인증 엔드포인트가 결정되면 여기에 토큰 발급/세션 주입 로직을 추가한다.
 */
export async function login(page: Page, _email: string, _password: string): Promise<void> {
  // TODO: 백엔드 인증 추가 후 구현
  await page.goto('/');
}

export async function getAuthToken(_email: string, _password: string): Promise<string> {
  // TODO: API 호출로 토큰 반환
  return 'TEST_TOKEN';
}
