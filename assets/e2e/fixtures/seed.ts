/**
 * E2E용 시드 데이터. 테스트 시작 전 백엔드에 주입한다.
 * 실제 사용 시 setup script(global-setup)에서 호출한다.
 */
export const seedUsers = [
  { email: 'tester@example.com', password: 'change-me-in-test-only', role: 'user' },
];
