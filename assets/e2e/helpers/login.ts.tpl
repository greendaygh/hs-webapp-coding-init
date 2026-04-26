import { Page } from '@playwright/test';

/**
 * Mock OIDC 로그인 헬퍼.
 *
 * - 백엔드의 OIDC_MOCK_ENABLED=true 가 전제.
 * - /api/v1/auth/login/mock?email=... 을 호출하면 백엔드가 세션 쿠키(sid)를 발급하고
 *   OIDC_POST_LOGIN_REDIRECT 로 리다이렉트한다.
 * - Playwright 의 BrowserContext 가 쿠키를 자동으로 보관하므로, 이 함수 호출 후
 *   page 는 인증된 세션을 갖는다.
 */
export async function loginAsMock(page: Page, email = 'tester@example.com'): Promise<void> {
  await page.goto(`{{api_v1_prefix}}/auth/login/mock?email=${encodeURIComponent(email)}`);
}

export async function logout(page: Page): Promise<void> {
  await page.request.post(`{{api_v1_prefix}}/auth/logout`);
}
