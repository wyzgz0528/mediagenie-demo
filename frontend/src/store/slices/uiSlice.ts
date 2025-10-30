import { createSlice, PayloadAction } from '@reduxjs/toolkit';

// 类型定义
export interface Notification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message: string;
  duration?: number;
  timestamp: number;
}

export interface UIState {
  theme: 'light' | 'dark' | 'auto';
  sidebarCollapsed: boolean;
  loading: {
    global: boolean;
    [key: string]: boolean;
  };
  notifications: Notification[];
  modals: {
    [key: string]: {
      visible: boolean;
      data?: any;
    };
  };
  breadcrumbs: Array<{
    title: string;
    path?: string;
  }>;
  pageTitle: string;
  pageDescription?: string;
}

// 初始状态
const initialState: UIState = {
  theme: 'light',
  sidebarCollapsed: false,
  loading: {
    global: false,
  },
  notifications: [],
  modals: {},
  breadcrumbs: [],
  pageTitle: 'MediaGenie',
  pageDescription: undefined,
};

// Slice
const uiSlice = createSlice({
  name: 'ui',
  initialState,
  reducers: {
    setTheme: (state, action: PayloadAction<'light' | 'dark' | 'auto'>) => {
      state.theme = action.payload;
      // 保存到localStorage
      localStorage.setItem('theme', action.payload);
    },
    
    toggleSidebar: (state) => {
      state.sidebarCollapsed = !state.sidebarCollapsed;
      // 保存到localStorage
      localStorage.setItem('sidebarCollapsed', String(state.sidebarCollapsed));
    },
    
    setSidebarCollapsed: (state, action: PayloadAction<boolean>) => {
      state.sidebarCollapsed = action.payload;
      localStorage.setItem('sidebarCollapsed', String(action.payload));
    },
    
    setGlobalLoading: (state, action: PayloadAction<boolean>) => {
      state.loading.global = action.payload;
    },
    
    setLoading: (state, action: PayloadAction<{ key: string; loading: boolean }>) => {
      const { key, loading } = action.payload;
      state.loading[key] = loading;
    },
    
    addNotification: (state, action: PayloadAction<Omit<Notification, 'id' | 'timestamp'>>) => {
      const notification: Notification = {
        ...action.payload,
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        timestamp: Date.now(),
      };
      state.notifications.unshift(notification);
      
      // 限制通知数量
      if (state.notifications.length > 10) {
        state.notifications = state.notifications.slice(0, 10);
      }
    },
    
    removeNotification: (state, action: PayloadAction<string>) => {
      state.notifications = state.notifications.filter(
        notification => notification.id !== action.payload
      );
    },
    
    clearNotifications: (state) => {
      state.notifications = [];
    },
    
    showModal: (state, action: PayloadAction<{ key: string; data?: any }>) => {
      const { key, data } = action.payload;
      state.modals[key] = {
        visible: true,
        data,
      };
    },
    
    hideModal: (state, action: PayloadAction<string>) => {
      const key = action.payload;
      if (state.modals[key]) {
        state.modals[key].visible = false;
        state.modals[key].data = undefined;
      }
    },
    
    setBreadcrumbs: (state, action: PayloadAction<Array<{ title: string; path?: string }>>) => {
      state.breadcrumbs = action.payload;
    },
    
    setPageTitle: (state, action: PayloadAction<string>) => {
      state.pageTitle = action.payload;
      // 更新浏览器标题
      document.title = `${action.payload} - MediaGenie`;
    },
    
    setPageDescription: (state, action: PayloadAction<string | undefined>) => {
      state.pageDescription = action.payload;
    },
    
    setPageInfo: (state, action: PayloadAction<{
      title: string;
      description?: string;
      breadcrumbs?: Array<{ title: string; path?: string }>;
    }>) => {
      const { title, description, breadcrumbs } = action.payload;
      state.pageTitle = title;
      state.pageDescription = description;
      if (breadcrumbs) {
        state.breadcrumbs = breadcrumbs;
      }
      document.title = `${title} - MediaGenie`;
    },
    
    // 初始化UI状态（从localStorage恢复）
    initializeUI: (state) => {
      // 恢复主题设置
      const savedTheme = localStorage.getItem('theme') as 'light' | 'dark' | 'auto' | null;
      if (savedTheme) {
        state.theme = savedTheme;
      }
      
      // 恢复侧边栏状态
      const savedSidebarState = localStorage.getItem('sidebarCollapsed');
      if (savedSidebarState !== null) {
        state.sidebarCollapsed = savedSidebarState === 'true';
      }
    },
  },
});

export const {
  setTheme,
  toggleSidebar,
  setSidebarCollapsed,
  setGlobalLoading,
  setLoading,
  addNotification,
  removeNotification,
  clearNotifications,
  showModal,
  hideModal,
  setBreadcrumbs,
  setPageTitle,
  setPageDescription,
  setPageInfo,
  initializeUI,
} = uiSlice.actions;

export default uiSlice.reducer;
