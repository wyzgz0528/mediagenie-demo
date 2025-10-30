/**
 * 认证服务
 * 处理 Azure AD 认证和令牌管理
 */

import { jwtDecode } from 'jwt-decode';
import {
  msalInstance,
  loginRequest,
  getAccessToken,
  loginUser,
  logoutUser,
  getCurrentAccount,
  isUserAuthenticated,
} from '../config/msalConfig';
import { User } from '../store/slices/authSlice';

/**
 * 从 JWT 令牌中提取用户信息
 * @param token JWT 令牌
 * @returns 用户信息
 */
export const extractUserFromToken = (token: string): Partial<User> | null => {
  try {
    const decoded: any = jwtDecode(token);
    
    return {
      id: decoded.oid || decoded.sub,
      email: decoded.email || decoded.preferred_username,
      name: decoded.name || decoded.given_name,
      role: decoded.roles?.[0] || 'user',
    };
  } catch (error) {
    console.error('❌ 解析 JWT 令牌失败:', error);
    return null;
  }
};

/**
 * 登录用户
 * @returns 用户信息和令牌
 */
export const authenticateUser = async () => {
  try {
    // 使用 MSAL 登录
    const response = await loginUser();
    
    if (!response.accessToken) {
      throw new Error('未获取到访问令牌');
    }

    // 从令牌中提取用户信息
    const userInfo = extractUserFromToken(response.accessToken);
    
    if (!userInfo) {
      throw new Error('无法解析用户信息');
    }

    // 保存令牌到 localStorage
    localStorage.setItem('accessToken', response.accessToken);
    localStorage.setItem('idToken', response.idToken || '');
    
    // 保存用户信息
    localStorage.setItem('user', JSON.stringify(userInfo));

    console.log('✅ 用户认证成功:', userInfo);

    return {
      user: userInfo as User,
      token: response.accessToken,
      idToken: response.idToken,
    };
  } catch (error) {
    console.error('❌ 用户认证失败:', error);
    throw error;
  }
};

/**
 * 退出登录
 */
export const deauthenticateUser = async () => {
  try {
    // 使用 MSAL 退出登录
    await logoutUser();
    
    // 清除本地存储
    localStorage.removeItem('accessToken');
    localStorage.removeItem('idToken');
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');

    console.log('✅ 用户已退出登录');
  } catch (error) {
    console.error('❌ 退出登录失败:', error);
    throw error;
  }
};

/**
 * 获取有效的访问令牌
 * @returns 访问令牌
 */
export const getValidAccessToken = async (): Promise<string | null> => {
  try {
    // 首先检查 localStorage 中是否有令牌
    const storedToken = localStorage.getItem('accessToken');
    
    if (storedToken) {
      // 检查令牌是否过期
      try {
        const decoded: any = jwtDecode(storedToken);
        const expirationTime = decoded.exp * 1000; // 转换为毫秒
        
        if (expirationTime > Date.now()) {
          // 令牌仍然有效
          return storedToken;
        }
      } catch (error) {
        console.warn('⚠️ 无法解析存储的令牌');
      }
    }

    // 尝试从 MSAL 获取新令牌
    const token = await getAccessToken(loginRequest.scopes);
    
    if (token) {
      localStorage.setItem('accessToken', token);
      return token;
    }

    return null;
  } catch (error) {
    console.error('❌ 获取访问令牌失败:', error);
    return null;
  }
};

/**
 * 检查用户是否已认证
 * @returns 是否已认证
 */
export const checkAuthentication = (): boolean => {
  // 检查 MSAL 状态
  if (isUserAuthenticated()) {
    return true;
  }

  // 检查 localStorage 中是否有令牌
  const token = localStorage.getItem('accessToken');
  if (token) {
    try {
      const decoded: any = jwtDecode(token);
      const expirationTime = decoded.exp * 1000;
      
      if (expirationTime > Date.now()) {
        return true;
      }
    } catch (error) {
      console.warn('⚠️ 无法验证存储的令牌');
    }
  }

  return false;
};

/**
 * 获取当前用户信息
 * @returns 用户信息
 */
export const getCurrentUser = (): User | null => {
  try {
    // 首先尝试从 MSAL 获取账户
    const account = getCurrentAccount();
    
    if (account) {
      return {
        id: account.localAccountId,
        email: account.username,
        name: account.name || '',
        role: 'user',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
    }

    // 尝试从 localStorage 获取用户信息
    const userStr = localStorage.getItem('user');
    if (userStr) {
      const user = JSON.parse(userStr);
      return {
        ...user,
        createdAt: user.createdAt || new Date().toISOString(),
        updatedAt: user.updatedAt || new Date().toISOString(),
      };
    }

    return null;
  } catch (error) {
    console.error('❌ 获取当前用户信息失败:', error);
    return null;
  }
};

/**
 * 初始化认证状态
 * 在应用启动时调用
 */
export const initializeAuth = async () => {
  try {
    // 检查用户是否已认证
    if (checkAuthentication()) {
      console.log('✅ 用户已认证');
      return true;
    }

    console.log('⚠️ 用户未认证');
    return false;
  } catch (error) {
    console.error('❌ 初始化认证失败:', error);
    return false;
  }
};

export default {
  authenticateUser,
  deauthenticateUser,
  getValidAccessToken,
  checkAuthentication,
  getCurrentUser,
  initializeAuth,
};

