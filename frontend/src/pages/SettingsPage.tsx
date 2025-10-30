import React, { useEffect, useState } from 'react';
import { 
  Card, 
  Form, 
  Input, 
  Button, 
  Select, 
  Switch, 
  Typography, 
  Space, 
  Divider,
  Row,
  Col,
  Avatar,
  Upload,
  message,
  Modal,
  Alert
} from 'antd';
import { 
  UserOutlined, 
  MailOutlined, 
  PhoneOutlined,
  TeamOutlined,
  LockOutlined,
  UploadOutlined,
  DeleteOutlined,
  ExclamationCircleOutlined
} from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

import { useAppDispatch, useAppSelector } from '../store';
// import { updateProfile, changePassword, deleteAccount } from '../store/slices/authSlice';
import { setPageInfo } from '../store/slices/uiSlice';

const { Title, Text } = Typography;

interface ProfileFormData {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  company?: string;
  language: string;
  timezone: string;
  emailNotifications: boolean;
  smsNotifications: boolean;
}

interface PasswordFormData {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}

const SettingsPage: React.FC = () => {
  const { t } = useTranslation();
  const dispatch = useAppDispatch();
  
  const { user, isLoading } = useAppSelector((state) => state.auth);
  
  // 表单实例
  const [profileForm] = Form.useForm();
  const [passwordForm] = Form.useForm();
  
  // 本地状态
  const [activeTab, setActiveTab] = useState('profile');
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const [deleteModalVisible, setDeleteModalVisible] = useState(false);
  
  useEffect(() => {
    // 设置页面信息
    dispatch(setPageInfo({
      title: t('settings.title'),
      description: t('settings.description') as string,
      breadcrumbs: [
        { title: t('nav.dashboard'), path: '/dashboard' },
        { title: t('nav.settings') }
      ]
    }));
    
    // 初始化表单数据
    if (user) {
      profileForm.setFieldsValue({
        firstName: user.name?.split(' ')[0] || '',
        lastName: user.name?.split(' ')[1] || '',
        email: user.email,
        phone: (user as any).phone || '',
        company: (user as any).company || '',
        language: user.preferences?.language || 'zh-CN',
        timezone: (user as any).timezone || 'Asia/Shanghai',
        emailNotifications: user.preferences?.notifications !== false,
        smsNotifications: (user as any).smsNotifications === true,
      });
      
      if ((user as any).avatarUrl) {
        setAvatarUrl((user as any).avatarUrl);
      }
    }
  }, [dispatch, t, user, profileForm]);
  
  // 语言选项
  const languageOptions = [
    { value: 'zh-CN', label: '中文（简体）' },
    { value: 'zh-TW', label: '中文（繁体）' },
    { value: 'en-US', label: 'English' },
    { value: 'ja-JP', label: '日本語' },
    { value: 'ko-KR', label: '한국어' },
  ];
  
  // 时区选项
  const timezoneOptions = [
    { value: 'Asia/Shanghai', label: '北京时间 (UTC+8)' },
    { value: 'Asia/Tokyo', label: '东京时间 (UTC+9)' },
    { value: 'Asia/Seoul', label: '首尔时间 (UTC+9)' },
    { value: 'America/New_York', label: '纽约时间 (UTC-5)' },
    { value: 'America/Los_Angeles', label: '洛杉矶时间 (UTC-8)' },
    { value: 'Europe/London', label: '伦敦时间 (UTC+0)' },
  ];
  
  // 头像上传配置
  const avatarUploadProps = {
    name: 'avatar',
    accept: '.jpg,.jpeg,.png',
    beforeUpload: (file: File) => {
      const isImage = file.type.startsWith('image/');
      if (!isImage) {
        message.error('只能上传图片文件！');
        return false;
      }
      
      const isLt2M = file.size / 1024 / 1024 < 2;
      if (!isLt2M) {
        message.error('图片大小不能超过 2MB！');
        return false;
      }
      
      // 创建预览URL
      const url = URL.createObjectURL(file);
      setAvatarUrl(url);
      
      return false; // 阻止自动上传
    },
  };
  
  // 更新个人资料
  const handleUpdateProfile = async (values: ProfileFormData) => {
    try {
      // await dispatch(updateProfile(values));
      message.success('个人资料更新成功（模拟）');
      message.success('个人资料更新成功');
    } catch (error) {
      message.error('个人资料更新失败');
    }
  };
  
  // 修改密码
  const handleChangePassword = async (values: PasswordFormData) => {
    try {
      // await dispatch(changePassword({
      //   currentPassword: values.currentPassword,
      //   newPassword: values.newPassword,
      // }));
      message.success('密码修改成功（模拟）');
      message.success('密码修改成功');
      passwordForm.resetFields();
    } catch (error) {
      message.error('密码修改失败');
    }
  };
  
  // 删除账户
  const handleDeleteAccount = async () => {
    try {
      // await dispatch(deleteAccount());
      message.success('账户删除成功（模拟）');
      message.success('账户删除成功');
    } catch (error) {
      message.error('账户删除失败');
    }
  };
  
  return (
    <div className="page-container">
      <Row gutter={[24, 24]}>
        {/* 左侧：个人资料 */}
        <Col xs={24} lg={12}>
          <Card title="个人资料">
            <Form
              form={profileForm}
              layout="vertical"
              onFinish={handleUpdateProfile}
              size="large"
            >
              {/* 头像上传 */}
              <div style={{ textAlign: 'center', marginBottom: '24px' }}>
                <Avatar
                  size={80}
                  src={avatarUrl}
                  icon={<UserOutlined />}
                  style={{ marginBottom: '16px' }}
                />
                <div>
                  <Upload {...avatarUploadProps} showUploadList={false}>
                    <Button icon={<UploadOutlined />}>更换头像</Button>
                  </Upload>
                </div>
              </div>
              
              <Row gutter={16}>
                <Col xs={24} sm={12}>
                  <Form.Item
                    name="firstName"
                    label="名字"
                    rules={[
                      { required: true, message: '请输入您的名字' },
                      { min: 2, message: '名字至少需要2个字符' },
                    ]}
                  >
                    <Input prefix={<UserOutlined />} placeholder="请输入您的名字" />
                  </Form.Item>
                </Col>
                
                <Col xs={24} sm={12}>
                  <Form.Item
                    name="lastName"
                    label="姓氏"
                    rules={[
                      { required: true, message: '请输入您的姓氏' },
                      { min: 2, message: '姓氏至少需要2个字符' },
                    ]}
                  >
                    <Input prefix={<UserOutlined />} placeholder="请输入您的姓氏" />
                  </Form.Item>
                </Col>
              </Row>
              
              <Form.Item
                name="email"
                label="邮箱地址"
                rules={[
                  { required: true, message: '请输入邮箱地址' },
                  { type: 'email', message: '请输入有效的邮箱地址' },
                ]}
              >
                <Input prefix={<MailOutlined />} placeholder="请输入邮箱地址" />
              </Form.Item>
              
              <Form.Item
                name="phone"
                label="手机号码"
                rules={[
                  { pattern: /^1[3-9]\d{9}$/, message: '请输入有效的手机号码' },
                ]}
              >
                <Input prefix={<PhoneOutlined />} placeholder="请输入手机号码" />
              </Form.Item>
              
              <Form.Item
                name="company"
                label="公司名称"
              >
                <Input prefix={<TeamOutlined />} placeholder="请输入公司名称" />
              </Form.Item>
              
              <Row gutter={16}>
                <Col xs={24} sm={12}>
                  <Form.Item
                    name="language"
                    label="界面语言"
                    rules={[{ required: true, message: '请选择界面语言' }]}
                  >
                    <Select options={languageOptions} placeholder="请选择界面语言" />
                  </Form.Item>
                </Col>
                
                <Col xs={24} sm={12}>
                  <Form.Item
                    name="timezone"
                    label="时区设置"
                    rules={[{ required: true, message: '请选择时区' }]}
                  >
                    <Select options={timezoneOptions} placeholder="请选择时区" />
                  </Form.Item>
                </Col>
              </Row>
              
              <Divider>通知设置</Divider>
              
              <Form.Item
                name="emailNotifications"
                valuePropName="checked"
                style={{ marginBottom: '16px' }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <Text strong>邮件通知</Text>
                    <div>
                      <Text type="secondary" style={{ fontSize: '12px' }}>
                        接收任务完成、账单等重要通知
                      </Text>
                    </div>
                  </div>
                  <Switch />
                </div>
              </Form.Item>
              
              <Form.Item
                name="smsNotifications"
                valuePropName="checked"
                style={{ marginBottom: '24px' }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <Text strong>短信通知</Text>
                    <div>
                      <Text type="secondary" style={{ fontSize: '12px' }}>
                        接收紧急通知和验证码
                      </Text>
                    </div>
                  </div>
                  <Switch />
                </div>
              </Form.Item>
              
              <Form.Item>
                <Button
                  type="primary"
                  htmlType="submit"
                  block
                  loading={isLoading}
                >
                  保存更改
                </Button>
              </Form.Item>
            </Form>
          </Card>
        </Col>
        
        {/* 右侧：安全设置 */}
        <Col xs={24} lg={12}>
          <Card title="安全设置" style={{ marginBottom: '24px' }}>
            <Form
              form={passwordForm}
              layout="vertical"
              onFinish={handleChangePassword}
              size="large"
            >
              <Form.Item
                name="currentPassword"
                label="当前密码"
                rules={[{ required: true, message: '请输入当前密码' }]}
              >
                <Input.Password
                  prefix={<LockOutlined />}
                  placeholder="请输入当前密码"
                />
              </Form.Item>
              
              <Form.Item
                name="newPassword"
                label="新密码"
                rules={[
                  { required: true, message: '请输入新密码' },
                  { min: 8, message: '密码至少需要8个字符' },
                  {
                    pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
                    message: '密码必须包含大小写字母和数字',
                  },
                ]}
              >
                <Input.Password
                  prefix={<LockOutlined />}
                  placeholder="请输入新密码（至少8位，包含大小写字母和数字）"
                />
              </Form.Item>
              
              <Form.Item
                name="confirmPassword"
                label="确认新密码"
                dependencies={['newPassword']}
                rules={[
                  { required: true, message: '请确认新密码' },
                  ({ getFieldValue }) => ({
                    validator(_, value) {
                      if (!value || getFieldValue('newPassword') === value) {
                        return Promise.resolve();
                      }
                      return Promise.reject(new Error('两次输入的密码不一致'));
                    },
                  }),
                ]}
              >
                <Input.Password
                  prefix={<LockOutlined />}
                  placeholder="请再次输入新密码"
                />
              </Form.Item>
              
              <Form.Item>
                <Button
                  type="primary"
                  htmlType="submit"
                  block
                  loading={isLoading}
                >
                  修改密码
                </Button>
              </Form.Item>
            </Form>
          </Card>
          
          {/* 危险操作 */}
          <Card title="危险操作">
            <Alert
              message="删除账户"
              description="删除账户后，您的所有数据将被永久删除且无法恢复。请谨慎操作。"
              type="warning"
              showIcon
              style={{ marginBottom: '16px' }}
            />
            
            <Button
              danger
              icon={<DeleteOutlined />}
              onClick={() => setDeleteModalVisible(true)}
            >
              删除账户
            </Button>
          </Card>
        </Col>
      </Row>
      
      {/* 删除账户确认模态框 */}
      <Modal
        title={
          <Space>
            <ExclamationCircleOutlined style={{ color: '#ff4d4f' }} />
            确认删除账户
          </Space>
        }
        open={deleteModalVisible}
        onCancel={() => setDeleteModalVisible(false)}
        onOk={handleDeleteAccount}
        okText="确认删除"
        cancelText="取消"
        okButtonProps={{ danger: true }}
      >
        <div style={{ padding: '16px 0' }}>
          <Alert
            message="此操作不可逆"
            description={
              <div>
                <p>删除账户后，以下数据将被永久删除：</p>
                <ul>
                  <li>个人资料和账户信息</li>
                  <li>所有任务历史记录</li>
                  <li>订阅和计费信息</li>
                  <li>API密钥和集成配置</li>
                </ul>
                <p><strong>此操作无法撤销，请确认您真的要删除账户。</strong></p>
              </div>
            }
            type="error"
            showIcon
          />
        </div>
      </Modal>
    </div>
  );
};

export default SettingsPage;
