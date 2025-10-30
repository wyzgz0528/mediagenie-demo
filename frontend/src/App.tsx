import React, { useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { useAppDispatch } from './store';
import { initializeUI } from './store/slices/uiSlice';

// 布局组件
import MainLayout from './components/layouts/MainLayout';

// 页面组件
import DashboardPage from './pages/DashboardPage';
import SpeechToTextPage from './pages/SpeechToTextPage';
import TextToSpeechPage from './pages/TextToSpeechPage';
import ImageAnalysisPage from './pages/ImageAnalysisPage';
import GPTChatPage from './pages/GPTChatPage';
import NotFoundPage from './pages/NotFoundPage';

// 简化的页面包装组件 - 不需要认证，直接访问
const PageWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return <MainLayout>{children}</MainLayout>;
};

const App: React.FC = () => {
  const dispatch = useAppDispatch();
  const { i18n } = useTranslation();
  
  useEffect(() => {
    // 初始化UI状态
    dispatch(initializeUI());
  }, [dispatch]);
  
  useEffect(() => {
    // 设置HTML语言属性
    document.documentElement.lang = i18n.language;
  }, [i18n.language]);
  
  return (
    <div className="App">
      <Routes>
        {/* 主应用页面 - 无需认证，直接访问 */}
        <Route path="/dashboard" element={
          <PageWrapper>
            <DashboardPage />
          </PageWrapper>
        } />
        
        <Route path="/speech-to-text" element={
          <PageWrapper>
            <SpeechToTextPage />
          </PageWrapper>
        } />
        
        <Route path="/text-to-speech" element={
          <PageWrapper>
            <TextToSpeechPage />
          </PageWrapper>
        } />
        
        <Route path="/image-analysis" element={
          <PageWrapper>
            <ImageAnalysisPage />
          </PageWrapper>
        } />

        <Route path="/gpt-chat" element={
          <PageWrapper>
            <GPTChatPage />
          </PageWrapper>
        } />
        
        {/* 默认重定向 */}
        <Route path="/" element={
          <Navigate to="/dashboard" replace />
        } />
        
        {/* 404页面 */}
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </div>
  );
};

export default App;
