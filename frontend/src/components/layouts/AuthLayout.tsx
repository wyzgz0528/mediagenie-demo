import React from 'react';
import { Layout, Card, Typography, Space } from 'antd';
import { useTranslation } from 'react-i18next';

const { Content } = Layout;
const { Title, Text } = Typography;

interface AuthLayoutProps {
  children: React.ReactNode;
}

const AuthLayout: React.FC<AuthLayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  
  return (
    <Layout style={{ minHeight: '100vh', background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
      <Content style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center',
        padding: '20px'
      }}>
        <div style={{ width: '100%', maxWidth: '400px' }}>
          {/* Logo和标题 */}
          <div style={{ textAlign: 'center', marginBottom: '32px' }}>
            <div style={{
              width: '80px',
              height: '80px',
              background: 'rgba(255, 255, 255, 0.2)',
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 16px',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(255, 255, 255, 0.3)'
            }}>
              <span style={{ 
                fontSize: '32px', 
                fontWeight: 'bold', 
                color: 'white',
                textShadow: '0 2px 4px rgba(0,0,0,0.3)'
              }}>
                MG
              </span>
            </div>
            <Title level={2} style={{ 
              color: 'white', 
              marginBottom: '8px',
              textShadow: '0 2px 4px rgba(0,0,0,0.3)',
              letterSpacing: '1px'
            }}>
              智网同盛 MediaGenie
            </Title>
            <Text style={{ 
              color: 'rgba(255, 255, 255, 0.8)', 
              fontSize: '16px',
              textShadow: '0 1px 2px rgba(0,0,0,0.3)'
            }}>
              多媒体内容智能管理平台
            </Text>
          </div>
          
          {/* 认证表单卡片 */}
          <Card
            style={{
              boxShadow: '0 8px 32px rgba(0, 0, 0, 0.12)',
              borderRadius: '12px',
              border: 'none',
              backdropFilter: 'blur(10px)',
              background: 'rgba(255, 255, 255, 0.95)'
            }}
            bodyStyle={{ padding: '32px' }}
          >
            {children}
          </Card>
          
          {/* 底部信息 */}
          <div style={{ 
            textAlign: 'center', 
            marginTop: '24px',
            color: 'rgba(255, 255, 255, 0.7)'
          }}>
            <Space direction="vertical" size="small">
              <Text style={{ 
                color: 'rgba(255, 255, 255, 0.7)',
                textShadow: '0 1px 2px rgba(0,0,0,0.3)',
                fontWeight: 500,
                fontSize: '15px'
              }}>
                深圳智网同盛科技有限公司
              </Text>
              <Text style={{ 
                color: 'rgba(255, 255, 255, 0.7)',
                textShadow: '0 1px 2px rgba(0,0,0,0.3)',
                fontSize: '14px'
              }}>
                <span style={{marginRight: '6px', verticalAlign: 'middle'}}>📧</span>联系邮箱：<a href="mailto:wangyizhe@itnellnet.cn" style={{color: 'white', textDecoration: 'underline'}}>wangyizhe@itnellnet.cn</a>
              </Text>
              <Text style={{ 
                color: 'rgba(255, 255, 255, 0.6)',
                fontSize: '13px'
              }}>
                © 2024 智网同盛 MediaGenie. 保留所有权利。
              </Text>
            </Space>
          </div>
        </div>
      </Content>
    </Layout>
  );
};

export default AuthLayout;
