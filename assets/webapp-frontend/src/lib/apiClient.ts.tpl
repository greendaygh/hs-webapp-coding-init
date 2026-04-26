import axios from 'axios';

const baseURL = import.meta.env.VITE_API_BASE_URL ?? '';

export const apiClient = axios.create({
  baseURL,
  timeout: 10_000,
  // 백엔드가 발급한 HTTP-only 세션 쿠키(sid)가 cross-origin 요청에서도 동행하도록 함.
  withCredentials: true,
});
