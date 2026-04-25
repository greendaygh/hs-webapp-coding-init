module.exports = {
  '*.{ts,tsx,js,jsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml,css}': ['prettier --write'],
  // 변경 파일 관련 vitest만 실행
  '**/*.{ts,tsx,js,jsx}': () => 'npx vitest related --run --reporter=default',
};
