import type { UserDto } from "../types";

const ACCESS_TOKEN_KEY = "accessToken";
const REFRESH_TOKEN_KEY = "refreshToken";
const AUTH_USER_KEY = "authUser";

export interface AuthSession {
  accessToken: string | null;
  refreshToken: string | null;
  user: UserDto | null;
}

export function readAuthSession(): AuthSession {
  const accessToken = localStorage.getItem(ACCESS_TOKEN_KEY);
  const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
  const userJson = localStorage.getItem(AUTH_USER_KEY);

  let user: UserDto | null = null;
  if (userJson) {
    try {
      user = JSON.parse(userJson) as UserDto;
    } catch {
      localStorage.removeItem(AUTH_USER_KEY);
    }
  }

  return { accessToken, refreshToken, user };
}

export function writeAuthSession(session: Partial<AuthSession>) {
  if (session.accessToken !== undefined) {
    if (session.accessToken) {
      localStorage.setItem(ACCESS_TOKEN_KEY, session.accessToken);
    } else {
      localStorage.removeItem(ACCESS_TOKEN_KEY);
    }
  }

  if (session.refreshToken !== undefined) {
    if (session.refreshToken) {
      localStorage.setItem(REFRESH_TOKEN_KEY, session.refreshToken);
    } else {
      localStorage.removeItem(REFRESH_TOKEN_KEY);
    }
  }

  if (session.user !== undefined) {
    if (session.user) {
      localStorage.setItem(AUTH_USER_KEY, JSON.stringify(session.user));
    } else {
      localStorage.removeItem(AUTH_USER_KEY);
    }
  }
}

export function clearAuthSession() {
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(AUTH_USER_KEY);
}

export function getAccessToken() {
  return localStorage.getItem(ACCESS_TOKEN_KEY);
}

export function getRefreshToken() {
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}
