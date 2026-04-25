import { expect, test } from '@playwright/test';

test('home page loads and shows project name', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1, name: '{{project_name}}' })).toBeVisible();
});

test('backend health is reachable', async ({ request }) => {
  const res = await request.get('{{health_endpoint}}');
  expect(res.ok()).toBe(true);
  const body = await res.json();
  expect(body.status).toBe('ok');
});
