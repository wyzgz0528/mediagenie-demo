import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { message } from 'antd';
import * as authService from '../../services/authService';

// 类型定义
export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  role: string;
  subscription?: {
    plan: string;
    status: string;
    expiresAt?: string;
  };
  preferences?: {
    language: string;
    theme: string;
    notifications: boolean;
  };
  createdAt: string;
  updatedAt: string;
}

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  token: string | null;
  refreshToken: string | null;
}

// 模拟用户数据（开发环境）
const mockUser: User = {
  id: 'dev-user-1',
  email: 'demo@mediagenie.com',
  name: 'MediaGenie 演示用户',
  role: 'user',
  subscription: {
    plan: 'premium',
    status: 'active',
  },
  preferences: {
    language: 'zh-CN',
    theme: 'light',
    notifications: true,
  },
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
};

// 初始状态
const initialState: AuthState = {
  user: mockUser, // 开发环境默认登录
  isAuthenticated: true, // 开发环境默认已认证
  isLoading: false,
  error: null,
  token: localStorage.getItem('token') || 'mock-dev-token',
  refreshToken: localStorage.getItem('refreshToken') || 'mock-dev-refresh-token',
};

// 异步actions - Azure AD 登录
export const loginWithAzureAD = createAsyncThunk(
  'auth/loginWithAzureAD',
  async (_, { rejectWithValue }) => {
    try {
      // 使用 Azure AD 进行认证
      const result = await authService.authenticateUser();

      message.success('Azure AD 登录成功');
      return {
        user: result.user,
        token: result.token,
        refreshToken: result.idToken,
      };
    } catch (error: any) {
      const errorMessage = error.message || 'Azure AD 登录失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

// 异步actions - 传统登录 (保留用于兼容性)
export const login = createAsyncThunk(
  'auth/login',
  async (credentials: { email: string; password: string }, { rejectWithValue }) => {
    try {
      // 模拟登录API调用
      await new Promise(resolve => setTimeout(resolve, 1000));

      // 模拟用户数据
      const mockUser: User = {
        id: '1',
        email: credentials.email,
        name: '测试用户',
        role: 'user',
        subscription: {
          plan: 'basic',
          status: 'active',
        },
        preferences: {
          language: 'zh-CN',
          theme: 'light',
          notifications: true,
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      const mockToken = 'mock-jwt-token';
      const mockRefreshToken = 'mock-refresh-token';

      // 保存到localStorage
      localStorage.setItem('token', mockToken);
      localStorage.setItem('refreshToken', mockRefreshToken);

      message.success('登录成功');
      return {
        user: mockUser,
        token: mockToken,
        refreshToken: mockRefreshToken,
      };
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '登录失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const logout = createAsyncThunk(
  'auth/logout',
  async (_, { rejectWithValue }) => {
    try {
      // 使用 Azure AD 退出登录
      await authService.deauthenticateUser();

      message.success('已退出登录');
      return null;
    } catch (error: any) {
      const errorMessage = error.message || '退出登录失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const refreshAuth = createAsyncThunk(
  'auth/refreshAuth',
  async (_, { rejectWithValue }) => {
    try {
      const refreshToken = localStorage.getItem('refreshToken');
      if (!refreshToken) {
        throw new Error('No refresh token available');
      }

      // 模拟刷新token API调用
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const newToken = 'new-mock-jwt-token';
      localStorage.setItem('token', newToken);

      return { token: newToken };
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '刷新认证失败';
      return rejectWithValue(errorMessage);
    }
  }
);

// Slice
const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload;
      state.isAuthenticated = true;
    },
    updateUser: (state, action: PayloadAction<Partial<User>>) => {
      if (state.user) {
        state.user = { ...state.user, ...action.payload };
      }
    },
    clearAuth: (state) => {
      state.user = null;
      state.isAuthenticated = false;
      state.token = null;
      state.refreshToken = null;
      localStorage.removeItem('token');
      localStorage.removeItem('refreshToken');
    },
  },
  extraReducers: (builder) => {
    builder
      // Azure AD Login
      .addCase(loginWithAzureAD.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(loginWithAzureAD.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.refreshToken = action.payload.refreshToken;
        state.isAuthenticated = true;
      })
      .addCase(loginWithAzureAD.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
        state.isAuthenticated = false;
      })

      // Traditional Login
      .addCase(login.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.refreshToken = action.payload.refreshToken;
        state.isAuthenticated = true;
      })
      .addCase(login.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
        state.isAuthenticated = false;
      })
      
      // Logout
      .addCase(logout.fulfilled, (state) => {
        state.user = null;
        state.token = null;
        state.refreshToken = null;
        state.isAuthenticated = false;
      })
      
      // Refresh Auth
      .addCase(refreshAuth.fulfilled, (state, action) => {
        state.token = action.payload.token;
      })
      .addCase(refreshAuth.rejected, (state) => {
        state.user = null;
        state.token = null;
        state.refreshToken = null;
        state.isAuthenticated = false;
        localStorage.removeItem('token');
        localStorage.removeItem('refreshToken');
      });
  },
});

export const {
  clearError,
  setUser,
  updateUser,
  clearAuth,
} = authSlice.actions;

export default authSlice.reducer;
