/**
 * MSAL (Microsoft Authentication Library) 配置
 * 用于 Azure AD 单点登录集成
 */

import { PublicClientApplication, Configuration, LogLevel } from '@azure/msal-browser';

// 从环境变量获取配置
const AZURE_AD_CLIENT_ID = process.env.REACT_APP_AZURE_AD_CLIENT_ID || 'your-client-id';
const AZURE_AD_TENANT_ID = process.env.REACT_APP_AZURE_AD_TENANT_ID || 'your-tenant-id';
const REDIRECT_URI = process.env.REACT_APP_REDIRECT_URI || 'http://localhost:3000';

// MSAL 配置
export const msalConfig: Configuration = {
  auth: {
    clientId: AZURE_AD_CLIENT_ID,
    authority: `https://login.microsoftonline.com/${AZURE_AD_TENANT_ID}`,
    redirectUri: REDIRECT_URI,
    postLogoutRedirectUri: REDIRECT_URI,
    navigateToLoginRequestUrl: true,
  },
  cache: {
    cacheLocation: 'localStorage', // 使用 localStorage 存储缓存
    storeAuthStateInCookie: false, // 在 localStorage 中存储认证状态
  },
  system: {
    loggerOptions: {
      loggerCallback: (level, message, containsPii) => {
        if (containsPii) {
          return;
        }
        switch (level) {
          case LogLevel.Error:
            console.error(message);
            return;
          case LogLevel.Info:
            console.info(message);
            return;
          case LogLevel.Verbose:
            console.debug(message);
            return;
          case LogLevel.Warning:
            console.warn(message);
            return;
          default:
            return;
        }
      },
      piiLoggingEnabled: false,
    },
  },
};

// 登录请求配置
export const loginRequest = {
  scopes: ['openid', 'profile', 'email'],
};

// API 请求配置（用于获取访问令牌）
export const apiRequest = {
  scopes: ['api://your-api-id/.default'], // 替换为你的 API ID
};

// 创建 MSAL 实例
export const msalInstance = new PublicClientApplication(msalConfig);

// 初始化 MSAL
export const initializeMsal = async () => {
  try {
    await msalInstance.initialize();
    console.log('✅ MSAL 初始化成功');
  } catch (error) {
    console.error('❌ MSAL 初始化失败:', error);
  }
};

/**
 * 获取访问令牌
 * @param scopes 请求的作用域
 * @returns 访问令牌
 */
export const getAccessToken = async (scopes: string[] = loginRequest.scopes): Promise<string | null> => {
  try {
    const account = msalInstance.getActiveAccount();
    
    if (!account) {
      console.warn('⚠️ 没有活跃的账户');
      return null;
    }

    const response = await msalInstance.acquireTokenSilent({
      scopes,
      account,
    });

    return response.accessToken;
  } catch (error) {
    console.error('❌ 获取访问令牌失败:', error);
    return null;
  }
};

/**
 * 登录用户
 * @returns 登录响应
 */
export const loginUser = async () => {
  try {
    const response = await msalInstance.loginPopup(loginRequest);
    console.log('✅ 登录成功:', response);
    return response;
  } catch (error) {
    console.error('❌ 登录失败:', error);
    throw error;
  }
};

/**
 * 退出登录
 */
export const logoutUser = async () => {
  try {
    await msalInstance.logoutPopup();
    console.log('✅ 退出登录成功');
  } catch (error) {
    console.error('❌ 退出登录失败:', error);
    throw error;
  }
};

/**
 * 获取当前用户账户
 * @returns 当前用户账户
 */
export const getCurrentAccount = () => {
  return msalInstance.getActiveAccount();
};

/**
 * 检查用户是否已认证
 * @returns 是否已认证
 */
export const isUserAuthenticated = (): boolean => {
  const account = msalInstance.getActiveAccount();
  return !!account;
};

export default msalInstance;

