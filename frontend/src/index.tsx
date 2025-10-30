import React from 'react';
import ReactDOM from 'react-dom/client';
import { Provider } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import { ConfigProvider } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';

import App from './App';
import { store } from './store';
import './i18n';
import './index.css';

// 设置dayjs为中文
dayjs.locale('zh-cn');

// Ant Design 中文主题配置
const antdConfig = {
  locale: zhCN,
  theme: {
    token: {
      colorPrimary: '#1890ff',
      colorSuccess: '#52c41a',
      colorWarning: '#faad14',
      colorError: '#ff4d4f',
      colorInfo: '#1890ff',
      borderRadius: 6,
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Helvetica Neue", Helvetica, Arial, sans-serif',
    },
    components: {
      Layout: {
        headerBg: '#ffffff',
        headerHeight: 64,
        siderBg: '#001529',
      },
      Menu: {
        darkItemBg: '#001529',
        darkSubMenuItemBg: '#000c17',
        darkItemSelectedBg: '#1890ff',
      },
      Button: {
        borderRadius: 6,
      },
      Input: {
        borderRadius: 6,
      },
      Card: {
        borderRadius: 8,
      },
    },
  },
};

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <Provider store={store}>
      <BrowserRouter>
        <ConfigProvider {...antdConfig}>
          <App />
        </ConfigProvider>
      </BrowserRouter>
    </Provider>
  </React.StrictMode>
);

// 性能监控
if (process.env.NODE_ENV === 'production') {
  import('./reportWebVitals').then(({ default: reportWebVitals }) => {
    reportWebVitals();
  });
}
