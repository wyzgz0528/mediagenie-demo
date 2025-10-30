import React, { useEffect } from 'react';
import { Row, Col, Card, Statistic, Button, List, Avatar, Tag, Progress, Typography, Space, Empty } from 'antd';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  AudioOutlined,
  SoundOutlined,
  PictureOutlined,
  UploadOutlined,
  HistoryOutlined,
  CreditCardOutlined,
  PlayCircleOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  ExclamationCircleOutlined,
} from '@ant-design/icons';

import { useAppDispatch, useAppSelector } from '../store';
import { fetchTasks } from '../store/slices/taskSlice';
import { fetchUsageSummary } from '../store/slices/billingSlice';
import { setPageInfo } from '../store/slices/uiSlice';

const { Title, Text, Paragraph } = Typography;

const DashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  
  const { user } = useAppSelector((state) => state.auth);
  const { tasks, isLoading: tasksLoading } = useAppSelector((state) => state.task);
  const { usageSummary, isLoading: billingLoading } = useAppSelector((state) => state.billing);
  
  useEffect(() => {
    // 设置页面信息
    dispatch(setPageInfo({
      title: t('dashboard.title'),
      breadcrumbs: [
        { title: t('nav.dashboard') }
      ]
    }));
    
    // 获取最近任务
    dispatch(fetchTasks({ page: 1, pageSize: 5 }));
    
    // 获取使用量概览
    dispatch(fetchUsageSummary());
  }, [dispatch, t]);
  
  // 快速操作按钮配置
  const quickActions = [
    {
      key: 'speech-to-text',
      title: '语音转写',
      description: '上传音频文件进行语音转写',
      icon: <AudioOutlined style={{ fontSize: '24px', color: '#1890ff' }} />,
      path: '/speech-to-text',
    },
    {
      key: 'text-to-speech',
      title: '文本转语音',
      description: '将文本转换为自然语音',
      icon: <SoundOutlined style={{ fontSize: '24px', color: '#52c41a' }} />,
      path: '/text-to-speech',
    },
    {
      key: 'image-analysis',
      title: '图像分析',
      description: '智能分析图像内容',
      icon: <PictureOutlined style={{ fontSize: '24px', color: '#fa8c16' }} />,
      path: '/image-analysis',
    },
  ];
  
  // 获取任务状态图标
  const getTaskStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <ClockCircleOutlined style={{ color: '#faad14' }} />;
      case 'processing':
        return <PlayCircleOutlined style={{ color: '#1890ff' }} />;
      case 'completed':
        return <CheckCircleOutlined style={{ color: '#52c41a' }} />;
      case 'failed':
        return <ExclamationCircleOutlined style={{ color: '#ff4d4f' }} />;
      default:
        return <ClockCircleOutlined />;
    }
  };
  
  // 获取任务状态标签
  const getTaskStatusTag = (status: string) => {
    const statusMap = {
      pending: { color: 'orange', text: '等待中' },
      processing: { color: 'blue', text: '处理中' },
      completed: { color: 'green', text: '已完成' },
      failed: { color: 'red', text: '失败' },
    };
    
    const config = statusMap[status as keyof typeof statusMap] || { color: 'default', text: status };
    return <Tag color={config.color}>{config.text}</Tag>;
  };
  
  // 获取任务类型显示名称
  const getTaskTypeName = (taskType: string) => {
    const typeMap = {
      'speech_to_text': '语音转写',
      'text_to_speech': '文本转语音',
      'image_analysis': '图像分析',
    };
    return typeMap[taskType as keyof typeof typeMap] || taskType;
  };
  
  // 计算使用率百分比
  const getUsagePercentage = (used: number, limit: number) => {
    if (limit === -1) return 0; // 无限制
    return Math.min((used / limit) * 100, 100);
  };
  
  return (
    <div className="page-container">
      {/* 欢迎信息 */}
      <div style={{ marginBottom: '24px' }}>
        <Title level={2} style={{ marginBottom: '8px' }}>
          {t('dashboard.welcome')}，{user?.name || '用户'}！
        </Title>
        <Paragraph type="secondary">
          欢迎使用 MediaGenie 多媒体内容智能管理平台。您可以在这里快速访问各种AI服务，查看使用情况和管理您的账户。
        </Paragraph>
      </div>
      
      {/* 使用量概览 */}
      <Card 
        title="本月使用概览" 
        style={{ marginBottom: '24px' }}
        loading={billingLoading}
      >
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} lg={6}>
            <Card size="small" style={{ textAlign: 'center' }}>
              <Statistic
                title="语音转写"
                value={usageSummary?.speechMinutesUsed || 0}
                suffix={`/ ${usageSummary?.speechMinutesLimit === -1 ? '无限' : usageSummary?.speechMinutesLimit || 0} 分钟`}
                valueStyle={{ color: '#1890ff' }}
              />
              <Progress
                percent={getUsagePercentage(
                  usageSummary?.speechMinutesUsed || 0,
                  usageSummary?.speechMinutesLimit || 0
                )}
                size="small"
                showInfo={false}
                strokeColor="#1890ff"
                style={{ marginTop: '8px' }}
              />
            </Card>
          </Col>
          
          <Col xs={24} sm={12} lg={6}>
            <Card size="small" style={{ textAlign: 'center' }}>
              <Statistic
                title="文本转语音"
                value={usageSummary?.ttsCharactersUsed || 0}
                suffix={`/ ${usageSummary?.ttsCharactersLimit === -1 ? '无限' : usageSummary?.ttsCharactersLimit || 0} 字符`}
                valueStyle={{ color: '#52c41a' }}
              />
              <Progress
                percent={getUsagePercentage(
                  usageSummary?.ttsCharactersUsed || 0,
                  usageSummary?.ttsCharactersLimit || 0
                )}
                size="small"
                showInfo={false}
                strokeColor="#52c41a"
                style={{ marginTop: '8px' }}
              />
            </Card>
          </Col>
          
          <Col xs={24} sm={12} lg={6}>
            <Card size="small" style={{ textAlign: 'center' }}>
              <Statistic
                title="图像分析"
                value={usageSummary?.imageRequestsUsed || 0}
                suffix={`/ ${usageSummary?.imageRequestsLimit === -1 ? '无限' : usageSummary?.imageRequestsLimit || 0} 次`}
                valueStyle={{ color: '#fa8c16' }}
              />
              <Progress
                percent={getUsagePercentage(
                  usageSummary?.imageRequestsUsed || 0,
                  usageSummary?.imageRequestsLimit || 0
                )}
                size="small"
                showInfo={false}
                strokeColor="#fa8c16"
                style={{ marginTop: '8px' }}
              />
            </Card>
          </Col>
          
          <Col xs={24} sm={12} lg={6}>
            <Card size="small" style={{ textAlign: 'center' }}>
              <Statistic
                title="API调用"
                value={usageSummary?.apiCallsUsed || 0}
                suffix={`/ ${usageSummary?.apiCallsLimit === -1 ? '无限' : usageSummary?.apiCallsLimit || 0} 次`}
                valueStyle={{ color: '#722ed1' }}
              />
              <Progress
                percent={getUsagePercentage(
                  usageSummary?.apiCallsUsed || 0,
                  usageSummary?.apiCallsLimit || 0
                )}
                size="small"
                showInfo={false}
                strokeColor="#722ed1"
                style={{ marginTop: '8px' }}
              />
            </Card>
          </Col>
        </Row>
      </Card>
      
      <Row gutter={[24, 24]}>
        {/* 快速操作 */}
        <Col xs={24} lg={12}>
          <Card title={t('dashboard.quickActions')} style={{ height: '100%' }}>
            <Row gutter={[16, 16]}>
              {quickActions.map((action) => (
                <Col xs={24} key={action.key}>
                  <Card
                    size="small"
                    hoverable
                    onClick={() => navigate(action.path)}
                    style={{ cursor: 'pointer' }}
                    bodyStyle={{ padding: '16px' }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <div style={{ marginRight: '16px' }}>
                        {action.icon}
                      </div>
                      <div style={{ flex: 1 }}>
                        <Title level={5} style={{ margin: 0, marginBottom: '4px' }}>
                          {action.title}
                        </Title>
                        <Text type="secondary" style={{ fontSize: '12px' }}>
                          {action.description}
                        </Text>
                      </div>
                    </div>
                  </Card>
                </Col>
              ))}
            </Row>
            
            <div style={{ marginTop: '16px', textAlign: 'center' }}>
              <Space>
                <Button 
                  type="primary" 
                  icon={<UploadOutlined />}
                  onClick={() => navigate('/speech-to-text')}
                >
                  上传文件
                </Button>
                <Button 
                  icon={<HistoryOutlined />}
                  onClick={() => navigate('/history')}
                >
                  查看历史
                </Button>
              </Space>
            </div>
          </Card>
        </Col>
        
        {/* 最近任务 */}
        <Col xs={24} lg={12}>
          <Card 
            title={t('dashboard.recentTasks')}
            extra={
              <Button 
                type="link" 
                onClick={() => navigate('/history')}
                style={{ padding: 0 }}
              >
                {t('dashboard.viewAll')}
              </Button>
            }
            style={{ height: '100%' }}
          >
            {tasks.length === 0 ? (
              <Empty
                image={Empty.PRESENTED_IMAGE_SIMPLE}
                description="暂无任务记录"
                style={{ margin: '40px 0' }}
              >
                <Button 
                  type="primary" 
                  onClick={() => navigate('/speech-to-text')}
                >
                  创建第一个任务
                </Button>
              </Empty>
            ) : (
              <List
                dataSource={tasks.slice(0, 5)}
                loading={tasksLoading}
                renderItem={(task) => (
                  <List.Item>
                    <List.Item.Meta
                      avatar={
                        <Avatar 
                          icon={getTaskStatusIcon(task.status)}
                          style={{ backgroundColor: 'transparent' }}
                        />
                      }
                      title={
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span>{getTaskTypeName(task.taskType)}</span>
                          {getTaskStatusTag(task.status)}
                        </div>
                      }
                      description={
                        <div>
                          <div>{task.inputFileName || '未知文件'}</div>
                          <Text type="secondary" style={{ fontSize: '12px' }}>
                            {new Date(task.createdAt).toLocaleString('zh-CN')}
                          </Text>
                        </div>
                      }
                    />
                  </List.Item>
                )}
              />
            )}
          </Card>
        </Col>
      </Row>
      
      {/* 底部留白区域（美观） */}
      <div style={{ marginTop: '32px', textAlign: 'center', color: '#bbb', fontSize: '13px' }}>
        {/* 可自定义底部信息或留白 */}
      </div>
    </div>
  );
};

export default DashboardPage;
