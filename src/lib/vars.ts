/**
 * §5.1.4 (B4): 모든 변수 기본값의 단일 출처. README/문서의 변수표는 사본.
 */
export const STANDARD_DEFAULTS: Record<string, string> = {
  // 디렉터리
  cursor_dir: '.cursor',
  backend_dir: 'backend',
  frontend_dir: 'frontend',
  app_module: 'app',
  package_json_path: 'package.json',

  // 프로젝트 메타 (사용자가 init에서 입력하면 덮어쓰기)
  project_name: 'my-app',
  project_slug: 'my-app',
  description: 'FastAPI + React fullstack web application',
  author: '',
  license_spdx: 'MIT',

  // 도구 버전 (Reproducibility 단일 출처)
  node_version: '22',
  python_version: '3.12',
  poetry_version: '1.8.0',
  mongodb_version: '7.0',
  redis_version: '7.2-alpine',
  caddy_version: '2.8',

  // 컨테이너 / 포트
  db_container_prefix: 'my-app',
  frontend_dev_port: '5173',
  backend_dev_port: '8000',
  mongodb_host_port_dev: '27017',
  redis_host_port_dev: '6379',
  staging_port: '8080',
  frontend_prod_port: '5054',

  // FastAPI / API
  api_v1_prefix: '/api/v1',
  health_endpoint: '/health',
  db_kind: 'mongodb',
  cors_origins_default: 'http://localhost:5173,http://localhost:3000',

  // E2E
  playwright_workers: '4',

  // 데이터 디렉터리 (DB 영속성)
  mongodb_data_dir_dev: './data/mongodb/dev',
  mongodb_config_dir_dev: './data/mongodb/dev-config',
  redis_data_dir_dev: './data/redis/dev',
  prod_data_dir: '/opt/my-app/data',
  prod_backup_dir: './backups/mongodb/prod',

  // Caddy / 프록시
  proxy_domain: 'localhost',
  acme_email: 'admin@localhost',
  proxy_http_port: '80',
  proxy_https_port: '443',

  // Harness
  pid_dir: '.',
  log_dir: 'logs',

  // 자동 배포 시크릿 이름
  deploy_ssh_host_secret: 'DEPLOY_SSH_HOST',
  deploy_ssh_user_secret: 'DEPLOY_SSH_USER',
  deploy_ssh_key_secret: 'DEPLOY_SSH_KEY',
  deploy_path_secret: 'DEPLOY_PATH',

  // TDD / 문서
  coverage_threshold: '70',
  default_locale: 'ko',

  // Feature toggles (true / false 문자열 — preset when 평가용)
  enable_msw: 'true',
  enable_shadcn: 'true',
  enable_makefile: 'false',
  enable_architecture_md: 'false',
  enable_contributing_md: 'false',
  enable_gitleaks: 'false',
  enable_bandit: 'false',
  enable_ci_audit: 'false',
  enable_seed_dev_db: 'false',

  // v0.2 deferred toggles (preset webapp-fullstack의 when 게이트)
  enable_staging: 'false',
  enable_data_harness: 'false',
  enable_observability: 'false',
  enable_reproducibility: 'false',
  enable_onboarding_full: 'false',
  enable_deploy_staging: 'false',
  enable_deploy_production: 'false',
};

export function computeRuntimeVars(): Record<string, string> {
  const now = new Date();
  return {
    current_year: String(now.getFullYear()),
    current_date: now.toISOString().slice(0, 10),
    year: String(now.getFullYear()),
  };
}

/**
 * project_name → kebab-case slug.
 */
export function slugify(s: string): string {
  return s
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/[\s_]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * 변수 해석 우선순위 (오른쪽이 우선): defaults < runtime < prompted < cliVars
 * + deriveVars로 계산값 한 단계 채움
 */
export function resolveVars(opts: {
  prompted?: Record<string, string>;
  cliVars?: Record<string, string>;
  defaults?: Record<string, string>;
}): Record<string, string> {
  const merged: Record<string, string> = {
    ...STANDARD_DEFAULTS,
    ...computeRuntimeVars(),
    ...(opts.defaults || {}),
    ...(opts.prompted || {}),
    ...(opts.cliVars || {}),
  };
  return deriveVars(merged);
}

/**
 * 다른 변수에서 파생되는 계산 변수.
 */
export function deriveVars(v: Record<string, string>): Record<string, string> {
  const out = { ...v };

  // project_slug: 명시되지 않았으면 project_name에서 slug 생성
  if (!opts(v, 'project_slug') && v.project_name) {
    out.project_slug = slugify(v.project_name);
  }

  // db_container_prefix: project_slug fallback
  if (!opts(v, 'db_container_prefix') && out.project_slug) {
    out.db_container_prefix = out.project_slug;
  }

  // prod_data_dir: project_slug 반영 fallback
  if (!opts(v, 'prod_data_dir') && out.project_slug) {
    out.prod_data_dir = `/opt/${out.project_slug}/data`;
  }

  // is_locale_en: default_locale === 'en'
  out.is_locale_en = out.default_locale === 'en' ? 'true' : 'false';

  // acme_email: proxy_domain 기반 fallback
  if (!opts(v, 'acme_email') && out.proxy_domain) {
    out.acme_email = `admin@${out.proxy_domain}`;
  }

  return out;
}

function opts(v: Record<string, string>, key: string): boolean {
  // STANDARD_DEFAULTS 기본값과 다른지 (즉, 사용자가 명시적으로 설정했는지)
  return v[key] !== undefined && v[key] !== STANDARD_DEFAULTS[key];
}
