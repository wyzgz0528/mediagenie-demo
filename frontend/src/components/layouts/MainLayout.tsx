import React from 'react';
import { Layout, Menu, Button, Breadcrumb, Typography } from 'antd';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  DashboardOutlined,
  AudioOutlined,
  SoundOutlined,
  PictureOutlined,
  MessageOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  HomeOutlined,
} from '@ant-design/icons';

import { useAppDispatch, useAppSelector } from '../../store';
import { toggleSidebar } from '../../store/slices/uiSlice';

const { Header, Sider, Content } = Layout;
const { Title } = Typography;

interface MainLayoutProps {
  children: React.ReactNode;
}

const MainLayout: React.FC<MainLayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useAppDispatch();
  
  const { sidebarCollapsed, pageTitle } = useAppSelector((state) => state.ui);
  
  // 菜单项配置
  const menuItems = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: t('nav.dashboard'),
    },
    {
      key: '/speech-to-text',
      icon: <AudioOutlined />,
      label: t('nav.speechToText'),
    },
    {
      key: '/text-to-speech',
      icon: <SoundOutlined />,
      label: t('nav.textToSpeech'),
    },
    {
      key: '/image-analysis',
      icon: <PictureOutlined />,
      label: t('nav.imageAnalysis'),
    },
    {
      key: '/gpt-chat',
      icon: <MessageOutlined />,
      label: 'GPT智能助手',
    },
  ];
  
  // 处理菜单点击
  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key);
  };
  
  // 处理侧边栏折叠
  const handleToggleSidebar = () => {
    dispatch(toggleSidebar());
  };
  
  // 生成面包屑
  const generateBreadcrumbs = () => {
    const pathMap: Record<string, string> = {
      '/dashboard': t('nav.dashboard'),
      '/speech-to-text': t('nav.speechToText'),
      '/text-to-speech': t('nav.textToSpeech'),
      '/image-analysis': t('nav.imageAnalysis'),
      '/gpt-chat': 'GPT智能助手',
    };
    
    const currentPath = location.pathname;
    const breadcrumbItems = [
      {
        title: <HomeOutlined />,
        href: '/dashboard',
      },
    ];
    
    if (currentPath !== '/dashboard') {
      breadcrumbItems.push({
        title: <span>{pathMap[currentPath] || '未知页面'}</span>,
        href: currentPath,
      });
    }
    
    return breadcrumbItems;
  };
  
  return (
    <Layout style={{ minHeight: '100vh' }}>
      {/* 侧边栏 */}
      <Sider
        trigger={null}
        collapsible
        collapsed={sidebarCollapsed}
        width={240}
        style={{
          background: '#001529',
          boxShadow: '2px 0 8px rgba(0,0,0,0.15)',
        }}
      >
        {/* Logo */}
        <div style={{
          height: '64px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: sidebarCollapsed ? 'center' : 'flex-start',
          padding: sidebarCollapsed ? '0' : '0 24px',
          background: 'rgba(255, 255, 255, 0.05)',
          borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
        }}>
          {sidebarCollapsed ? (
            <span style={{ 
              color: 'white', 
              fontSize: '20px', 
              fontWeight: 'bold' 
            }}>
              MG
            </span>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <span style={{ 
                color: 'white', 
                fontSize: '20px', 
                fontWeight: 'bold',
                marginRight: '8px'
              }}>
                MG
              </span>
              <span style={{ 
                color: 'white', 
                fontSize: '16px',
                fontWeight: '500',
                letterSpacing: '1px'
              }}>
                智网同盛 MediaGenie
              </span>
            </div>
          )}
        </div>
        
        {/* 菜单 */}
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={handleMenuClick}
          style={{ 
            borderRight: 'none',
            background: 'transparent'
          }}
        />
      </Sider>
      
      {/* 主内容区域 */}
      <Layout>
        {/* 顶部导航栏 */}
        <Header style={{
          padding: '0 24px',
          background: '#fff',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
          zIndex: 1,
        }}>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Button
              type="text"
              icon={sidebarCollapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
              onClick={handleToggleSidebar}
              style={{ marginRight: '16px' }}
            />
            
            <Title level={4} style={{ margin: 0, color: '#262626' }}>
              {pageTitle}
            </Title>
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <span style={{ color: '#262626', fontSize: '14px', fontWeight: 500 }}>
              智网同盛 MediaGenie AI Platform
            </span>
          </div>
        </Header>
        
        {/* 面包屑导航 */}
        <div style={{
          padding: '16px 24px 0',
          background: '#fff',
          borderBottom: '1px solid #f0f0f0'
        }}>
          <Breadcrumb items={generateBreadcrumbs()} />
        </div>
        
        {/* 页面内容 */}
        <Content style={{
          margin: '0',
          padding: '24px',
          background: '#f0f2f5',
          minHeight: 'calc(100vh - 64px - 57px)', // 减去header和breadcrumb的高度
        }}>
          <div className="fade-in">
            {children}
          </div>
        </Content>
      </Layout>
    </Layout>
  );
};

export default MainLayout;
