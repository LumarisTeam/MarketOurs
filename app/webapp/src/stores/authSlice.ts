import { createSlice, type PayloadAction } from "@reduxjs/toolkit";
import type { UserDto } from "../types";
import {
  clearAuthSession,
  readAuthSession,
  writeAuthSession,
} from "../services/authSession";

interface AuthState {
  user: UserDto | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  isHydrated: boolean;
}

const storedSession = readAuthSession();

const initialState: AuthState = {
  user: storedSession.user,
  accessToken: storedSession.accessToken,
  isAuthenticated: !!storedSession.accessToken,
  isHydrated: false,
};

export const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setCredentials: (
      state,
      action: PayloadAction<{
        user: UserDto;
        accessToken: string;
        refreshToken: string;
      }>
    ) => {
      state.user = action.payload.user;
      state.accessToken = action.payload.accessToken;
      state.isAuthenticated = true;
      state.isHydrated = true;
      writeAuthSession(action.payload);
    },
    logout: (state) => {
      state.user = null;
      state.accessToken = null;
      state.isAuthenticated = false;
      state.isHydrated = true;
      clearAuthSession();
    },
    setUser: (state, action: PayloadAction<UserDto>) => {
      state.user = action.payload;
      state.isAuthenticated = true;
      state.isHydrated = true;
      writeAuthSession({ user: action.payload });
    },
    hydrateSession: (state, action: PayloadAction<{
      user: UserDto | null;
      accessToken: string | null;
    }>) => {
      state.user = action.payload.user;
      state.accessToken = action.payload.accessToken;
      state.isAuthenticated = !!action.payload.accessToken;
      state.isHydrated = true;
    },
    markHydrated: (state) => {
      state.isHydrated = true;
    },
  },
});

export const { setCredentials, logout, setUser, hydrateSession, markHydrated } =
  authSlice.actions;
export default authSlice.reducer;
