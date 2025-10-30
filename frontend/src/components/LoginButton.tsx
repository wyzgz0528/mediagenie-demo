/**
 * 登录按钮组件
 * 支持 Azure AD 单点登录
 */

import React from 'react';
import { Button, Dropdown, Space, Avatar, Menu, Spin } from 'antd';
import { UserOutlined, LogoutOutlined, LoginOutlined } from '@ant-design/icons';
import { useAppDispatch, useAppSelector } from '../store';
import { loginWithAzureAD, logout } from '../store/slices/authSlice';

interface LoginButtonProps {
  className?: string;
  style?: React.CSSProperties;
}

/**
 * 登录按钮组件
 */
const LoginButton: React.FC<LoginButtonProps> = ({ className, style }) => {
  const dispatch = useAppDispatch();
  const { user, isAuthenticated, isLoading } = useAppSelector((state) => state.auth);

  /**
   * 处理 Azure AD 登录
   */
  const handleAzureADLogin = async () => {
    try {
      await dispatch(loginWithAzureAD()).unwrap();
    } catch (error) {
      console.error('❌ Azure AD 登录失败:', error);
    }
  };

  /**
   * 处理退出登录
   */
  const handleLogout = async () => {
    try {
      await dispatch(logout()).unwrap();
    } catch (error) {
      console.error('❌ 退出登录失败:', error);
    }
  };

  // 如果正在加载，显示加载状态
  if (isLoading) {
    return (
      <Spin size="small" style={{ marginRight: '8px' }} />
    );
  }

  // 如果未认证，显示登录按钮
  if (!isAuthenticated || !user) {
    return (
      <Button
        type="primary"
        icon={<LoginOutlined />}
        onClick={handleAzureADLogin}
        className={className}
        style={style}
        loading={isLoading}
      >
        Azure AD 登录
      </Button>
    );
  }

  // 如果已认证，显示用户菜单
  const userMenu = (
    <Menu>
      <Menu.Item key="profile" icon={<UserOutlined />} disabled>
        <span>{user.email}</span>
      </Menu.Item>
      <Menu.Divider />
      <Menu.Item key="logout" icon={<LogoutOutlined />} onClick={handleLogout}>
        退出登录
      </Menu.Item>
    </Menu>
  );

  return (
    <Dropdown menu={{ items: userMenu.props.children as any }} trigger={['click']}>
      <Space style={{ cursor: 'pointer' }} className={className}>
        <Avatar
          size="small"
          icon={<UserOutlined />}
          style={{ backgroundColor: '#1890ff' }}
        />
        <span>{user.name || user.email}</span>
      </Space>
    </Dropdown>
  );
};

export default LoginButton;

