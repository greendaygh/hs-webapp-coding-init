import path from 'node:path';
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
  // 프로젝트 루트의 .env.<mode>를 읽음
  const env = loadEnv(mode, path.resolve(__dirname, '..'), '');
  const backendOrigin = env.VITE_BACKEND_ORIGIN ?? 'http://localhost:{{backend_dev_port}}';

  return {
    envDir: path.resolve(__dirname, '..'),
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src'),
      },
    },
    server: {
      port: {{frontend_dev_port}},
      strictPort: false,
      proxy: {
        '{{api_v1_prefix}}': {
          target: backendOrigin,
          changeOrigin: true,
        },
        '{{health_endpoint}}': {
          target: backendOrigin,
          changeOrigin: true,
        },
      },
    },
    build: {
      sourcemap: true,
      rollupOptions: {
        output: {
          manualChunks: {
            react: ['react', 'react-dom', 'react-router-dom'],
            query: ['@tanstack/react-query'],
            forms: ['react-hook-form', 'zod'],
          },
        },
      },
    },
  };
});
