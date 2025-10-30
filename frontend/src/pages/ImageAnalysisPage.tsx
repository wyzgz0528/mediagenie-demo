import React, { useState, useEffect } from 'react';
import { 
  Card, 
  Upload, 
  Button, 
  Checkbox, 
  Typography, 
  Space, 
  Alert,
  Divider,
  Row,
  Col,
  message,
  Progress,
  Tag,
  Image,
  List,
  Descriptions
} from 'antd';
import { 
  PictureOutlined, 
  DownloadOutlined, 
  EyeOutlined,
  FileTextOutlined,
  TagsOutlined,
  UserOutlined
} from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

import { useAppDispatch, useAppSelector } from '../store';
import { createImageAnalysisTask, setCurrentTask } from '../store/slices/taskSlice';
import { setPageInfo } from '../store/slices/uiSlice';

const { Title, Text, Paragraph } = Typography;
const { Dragger } = Upload;

const ImageAnalysisPage: React.FC = () => {
  const { t } = useTranslation();
  const dispatch = useAppDispatch();
  
  const { currentTask, isUploading, isProcessing } = useAppSelector((state) => state.task);
  
  // 本地状态
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [analysisTypes, setAnalysisTypes] = useState<string[]>(['ocr', 'objects']);
  
  useEffect(() => {
    // 设置页面信息
    dispatch(setPageInfo({
      title: t('imageAnalysis.title'),
      description: t('imageAnalysis.description') as string,
      breadcrumbs: [
        { title: t('nav.dashboard'), path: '/dashboard' },
        { title: t('nav.imageAnalysis') }
      ]
    }));
    
    // 清除当前任务
    dispatch(setCurrentTask(null));
  }, [dispatch, t]);
  
  // 分析类型选项
  const analysisOptions = [
    { value: 'ocr', label: 'OCR文字识别', icon: <FileTextOutlined /> },
    { value: 'objects', label: '对象检测', icon: <EyeOutlined /> },
    { value: 'faces', label: '人脸识别', icon: <UserOutlined /> },
    { value: 'tags', label: '标签提取', icon: <TagsOutlined /> },
  ];
  
  // 文件上传配置
  const uploadProps = {
    name: 'image',
    multiple: false,
    accept: '.jpg,.jpeg,.png,.gif,.webp',
    beforeUpload: (file: File) => {
      // 检查文件类型
      const isImage = file.type.startsWith('image/');
      
      if (!isImage) {
        message.error('请上传图像文件！');
        return false;
      }
      
      // 检查文件大小 (50MB)
      const isLt50M = file.size / 1024 / 1024 < 50;
      if (!isLt50M) {
        message.error('图像文件大小不能超过 50MB！');
        return false;
      }
      
      setSelectedFile(file);
      
      // 创建图像URL用于预览
      const url = URL.createObjectURL(file);
      setImageUrl(url);
      
      return false; // 阻止自动上传
    },
    onRemove: () => {
      setSelectedFile(null);
      if (imageUrl) {
        URL.revokeObjectURL(imageUrl);
        setImageUrl(null);
      }
    },
  };
  
  // 开始分析
  const handleStartAnalysis = async () => {
    if (!selectedFile) {
      message.error('请先选择图像文件！');
      return;
    }
    
    if (analysisTypes.length === 0) {
      message.error('请至少选择一种分析类型！');
      return;
    }
    
    try {
      await dispatch(createImageAnalysisTask({
        file: selectedFile,
        analysisTypes,
      }));
    } catch (error) {
      console.error('Image analysis error:', error);
    }
  };
  
  // 下载分析结果
  const handleDownloadResult = () => {
    if (currentTask?.result) {
      const blob = new Blob([JSON.stringify(currentTask.result, null, 2)], { 
        type: 'application/json;charset=utf-8' 
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `analysis_${currentTask.id}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }
  };
  
  return (
    <div className="page-container">
      <Row gutter={[24, 24]}>
        {/* 左侧：图像上传和设置 */}
        <Col xs={24} lg={12}>
          <Card title="上传图像文件" style={{ marginBottom: '24px' }}>
            <Dragger {...uploadProps} style={{ marginBottom: '16px' }}>
              <p className="ant-upload-drag-icon">
                <PictureOutlined style={{ fontSize: '48px', color: '#fa8c16' }} />
              </p>
              <p className="ant-upload-text">
                点击或拖拽图像文件到此区域上传
              </p>
              <p className="ant-upload-hint">
                支持格式：JPG, PNG, GIF, WEBP<br />
                最大文件大小：50MB
              </p>
            </Dragger>
            
            {selectedFile && (
              <Alert
                message={`已选择文件：${selectedFile.name}`}
                description={`文件大小：${(selectedFile.size / 1024 / 1024).toFixed(2)} MB`}
                type="success"
                showIcon
              />
            )}
            
            {/* 图像预览 */}
            {imageUrl && (
              <div style={{ marginTop: '16px', textAlign: 'center' }}>
                <Image
                  src={imageUrl}
                  alt="预览图像"
                  style={{ maxWidth: '100%', maxHeight: '300px' }}
                />
              </div>
            )}
          </Card>
          
          <Card title="分析设置">
            <Space direction="vertical" style={{ width: '100%' }} size="large">
              {/* 分析类型选择 */}
              <div>
                <Text strong>分析类型</Text>
                <div style={{ marginTop: '12px' }}>
                  <Checkbox.Group
                    value={analysisTypes}
                    onChange={setAnalysisTypes}
                    style={{ width: '100%' }}
                  >
                    <Row gutter={[16, 16]}>
                      {analysisOptions.map((option) => (
                        <Col xs={24} sm={12} key={option.value}>
                          <Checkbox value={option.value}>
                            <Space>
                              {option.icon}
                              {option.label}
                            </Space>
                          </Checkbox>
                        </Col>
                      ))}
                    </Row>
                  </Checkbox.Group>
                </div>
                <Text type="secondary" style={{ fontSize: '12px', display: 'block', marginTop: '8px' }}>
                  可以同时选择多种分析类型
                </Text>
              </div>
              
              {/* 开始分析按钮 */}
              <Button
                type="primary"
                size="large"
                block
                icon={<PictureOutlined />}
                onClick={handleStartAnalysis}
                loading={isUploading || isProcessing}
                disabled={!selectedFile || analysisTypes.length === 0}
              >
                {isUploading ? '上传中...' : isProcessing ? '分析中...' : '开始分析'}
              </Button>
            </Space>
          </Card>
        </Col>
        
        {/* 右侧：分析结果 */}
        <Col xs={24} lg={12}>
          <Card 
            title="分析结果"
            extra={
              currentTask?.status === 'completed' && (
                <Button
                  icon={<DownloadOutlined />}
                  onClick={handleDownloadResult}
                >
                  下载结果
                </Button>
              )
            }
          >
            {!currentTask ? (
              <div style={{ textAlign: 'center', padding: '60px 20px' }}>
                <PictureOutlined style={{ fontSize: '64px', color: '#d9d9d9', marginBottom: '16px' }} />
                <Title level={4} type="secondary">
                  请上传图像文件开始分析
                </Title>
                <Paragraph type="secondary">
                  支持多种分析类型，分析结果将在此处显示
                </Paragraph>
              </div>
            ) : (
              <div>
                {/* 任务状态 */}
                <div style={{ marginBottom: '16px' }}>
                  <Space>
                    <Text strong>状态：</Text>
                    {currentTask.status === 'pending' && <Tag color="orange">等待中</Tag>}
                    {currentTask.status === 'processing' && <Tag color="blue">分析中</Tag>}
                    {currentTask.status === 'completed' && <Tag color="green">已完成</Tag>}
                    {currentTask.status === 'failed' && <Tag color="red">失败</Tag>}
                  </Space>
                </div>
                
                {/* 处理进度 */}
                {(currentTask.status === 'processing' || currentTask.status === 'pending') && (
                  <div style={{ marginBottom: '16px' }}>
                    <Progress 
                      percent={currentTask.status === 'processing' ? 70 : 30}
                      status="active"
                      strokeColor="#fa8c16"
                    />
                    <Text type="secondary" style={{ fontSize: '12px' }}>
                      {currentTask.status === 'processing' ? '正在分析中，请稍候...' : '任务已提交，等待处理...'}
                    </Text>
                  </div>
                )}
                
                {/* 错误信息 */}
                {currentTask.status === 'failed' && currentTask.errorMessage && (
                  <Alert
                    message="图像分析失败"
                    description={currentTask.errorMessage}
                    type="error"
                    showIcon
                    style={{ marginBottom: '16px' }}
                  />
                )}
                
                {/* 分析结果 */}
                {currentTask.status === 'completed' && currentTask.result && (
                  <div>
                    {/* OCR结果 */}
                    {currentTask.result.ocr && (
                      <div style={{ marginBottom: '24px' }}>
                        <Divider orientation="left">
                          <FileTextOutlined /> OCR文字识别
                        </Divider>
                        {currentTask.result.ocr.text ? (
                          <div style={{ 
                            background: '#fafafa', 
                            padding: '12px', 
                            borderRadius: '6px',
                            fontSize: '14px',
                            lineHeight: '1.6'
                          }}>
                            {currentTask.result.ocr.text}
                          </div>
                        ) : (
                          <Text type="secondary">未检测到文字内容</Text>
                        )}
                      </div>
                    )}
                    
                    {/* 对象检测结果 */}
                    {currentTask.result.objects && (
                      <div style={{ marginBottom: '24px' }}>
                        <Divider orientation="left">
                          <EyeOutlined /> 对象检测
                        </Divider>
                        {currentTask.result.objects.length > 0 ? (
                          <List
                            size="small"
                            dataSource={currentTask.result.objects}
                            renderItem={(item: any) => (
                              <List.Item>
                                <Space>
                                  <Tag color="blue">{item.name}</Tag>
                                  <Text type="secondary">
                                    置信度: {(item.confidence * 100).toFixed(1)}%
                                  </Text>
                                </Space>
                              </List.Item>
                            )}
                          />
                        ) : (
                          <Text type="secondary">未检测到对象</Text>
                        )}
                      </div>
                    )}
                    
                    {/* 人脸识别结果 */}
                    {currentTask.result.faces && (
                      <div style={{ marginBottom: '24px' }}>
                        <Divider orientation="left">
                          <UserOutlined /> 人脸识别
                        </Divider>
                        {currentTask.result.faces.length > 0 ? (
                          <Descriptions size="small" column={1}>
                            <Descriptions.Item label="检测到人脸数量">
                              {currentTask.result.faces.length}
                            </Descriptions.Item>
                            {currentTask.result.faces.map((face: any, index: number) => (
                              <Descriptions.Item key={index} label={`人脸 ${index + 1}`}>
                                年龄: {face.age || '未知'} | 
                                性别: {face.gender || '未知'} | 
                                情绪: {face.emotion || '未知'}
                              </Descriptions.Item>
                            ))}
                          </Descriptions>
                        ) : (
                          <Text type="secondary">未检测到人脸</Text>
                        )}
                      </div>
                    )}
                    
                    {/* 标签提取结果 */}
                    {currentTask.result.tags && (
                      <div style={{ marginBottom: '24px' }}>
                        <Divider orientation="left">
                          <TagsOutlined /> 内容标签
                        </Divider>
                        {currentTask.result.tags.length > 0 ? (
                          <Space size={[8, 8]} wrap>
                            {currentTask.result.tags.map((tag: any, index: number) => (
                              <Tag key={index} color="orange">
                                {tag.name} ({(tag.confidence * 100).toFixed(1)}%)
                              </Tag>
                            ))}
                          </Space>
                        ) : (
                          <Text type="secondary">未提取到标签</Text>
                        )}
                      </div>
                    )}
                    
                    {/* 分析信息 */}
                    <div style={{ marginTop: '16px' }}>
                      <Text type="secondary" style={{ fontSize: '12px' }}>
                        分析类型：{analysisTypes.join(', ')} | 
                        处理时间：{currentTask.processingTime ? `${currentTask.processingTime}秒` : '未知'}
                      </Text>
                    </div>
                  </div>
                )}
              </div>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default ImageAnalysisPage;
