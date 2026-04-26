import { expect, test } from '@playwright/test';

import { loginAsMock } from '../helpers/login';

test('anonymous users are redirected to /login', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveURL(/\/login/);
});

test('mock login lets the user reach the protected home page', async ({ page }) => {
  await loginAsMock(page, 'e2e@example.com');
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1, name: '{{project_name}}' })).toBeVisible();
});

test('backend health is reachable', async ({ request }) => {
  const res = await request.get('{{health_endpoint}}');
  expect(res.ok()).toBe(true);
  const body = await res.json();
  expect(body.status).toBe('ok');
});
