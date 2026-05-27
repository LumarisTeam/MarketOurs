import type { ApiResponse } from '../types';
import {
  clearAuthSession,
  getAccessToken,
  getRefreshToken,
  writeAuthSession,
} from './authSession';
import { store } from '../stores';
import { logout } from '../stores/authSlice';

export const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5053';

let refreshPromise: Promise<string | null> | null = null;

function resetAuthState() {
  clearAuthSession();
  store.dispatch(logout());
}

async function parseResponse<T>(response: Response): Promise<ApiResponse<T>> {
  const data = await response.json();

  if (!response.ok) {
    throw data;
  }

  return data as ApiResponse<T>;
}

async function refreshAccessToken(): Promise<string | null> {
  if (!refreshPromise) {
    refreshPromise = (async () => {
      const refreshToken = getRefreshToken();
      if (!refreshToken) {
        resetAuthState();
        return null;
      }

      const response = await fetch(`${BASE_URL}/Auth/refresh`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          refreshToken,
          deviceType: 'Web',
        }),
      });

      try {
        const data = await parseResponse<{ accessToken: string; refreshToken: string }>(response);
        if (!data.data?.accessToken || !data.data?.refreshToken) {
          resetAuthState();
          return null;
        }

        writeAuthSession({
          accessToken: data.data.accessToken,
          refreshToken: data.data.refreshToken,
        });
        return data.data.accessToken;
      } catch {
        resetAuthState();
        return null;
      }
    })().finally(() => {
      refreshPromise = null;
    });
  }

  return refreshPromise;
}

async function request<T>(
  path: string,
  method: string = 'GET',
  body?: any,
  options: RequestInit = {},
  allowRetry: boolean = true
): Promise<ApiResponse<T>> {
  const token = getAccessToken();
  const headers = new Headers(options.headers);

  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  if (body && !(body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  const config: RequestInit = {
    ...options,
    method,
    headers,
  };

  if (body) {
    config.body = body instanceof FormData ? body : JSON.stringify(body);
  }

  const response = await fetch(`${BASE_URL}${path}`, config);

  if (response.status === 401 && allowRetry && path !== '/Auth/refresh') {
    const refreshedToken = await refreshAccessToken();
    if (refreshedToken) {
      return request<T>(path, method, body, options, false);
    }
  }

  return parseResponse<T>(response);
}

export const apiClient = {
  get: <T>(path: string, options?: RequestInit) => request<T>(path, 'GET', undefined, options),
  post: <T>(path: string, body?: any, options?: RequestInit) => request<T>(path, 'post', body, options),
  put: <T>(path: string, body?: any, options?: RequestInit) => request<T>(path, 'PUT', body, options),
  delete: <T>(path: string, options?: RequestInit) => request<T>(path, 'DELETE', undefined, options),
};
