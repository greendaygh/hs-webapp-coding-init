import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('{{health_endpoint}}', () =>
    HttpResponse.json({ status: 'ok', env: 'test' }),
  ),
];
