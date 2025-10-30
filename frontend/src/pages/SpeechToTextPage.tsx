import React, { useState, useEffect } from 'react';
import { 
  Card, 
  Upload, 
  Button, 
  Select, 
  Switch, 
  Input, 
  Tag, 
  Progress, 
  Typography, 
  Space, 
  Alert,
  Divider,
  Row,
  Col,
  message
} from 'antd';
import { 
  UploadOutlined, 
  AudioOutlined, 
  DownloadOutlined, 
  CopyOutlined,
  DeleteOutlined,
  PlayCircleOutlined,
  PauseCircleOutlined
} from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

import { useAppDispatch, useAppSelector } from '../store';
import { createSpeechToTextTask, setCurrentTask } from '../store/slices/taskSlice';
import { setPageInfo } from '../store/slices/uiSlice';

const { Title, Text, Paragraph } = Typography;
const { TextArea } = Input;
const { Dragger } = Upload;

const SpeechToTextPage: React.FC = () => {
  const { t } = useTranslation();
  const dispatch = useAppDispatch();
  
  const { currentTask, isUploading, isProcessing } = useAppSelector((state) => state.task);
  
  // 本地状态
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [language, setLanguage] = useState('zh-CN');
  const [speakerSeparation, setSpeakerSeparation] = useState(false);
  const [customVocabulary, setCustomVocabulary] = useState<string[]>([]);
  const [vocabularyInput, setVocabularyInput] = useState('');
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  
  useEffect(() => {
    // 设置页面信息
    dispatch(setPageInfo({
      title: t('speechToText.title'),
      description: t('speechToText.description') as string,
      breadcrumbs: [
        { title: t('nav.dashboard'), path: '/dashboard' },
        { title: t('nav.speechToText') }
      ]
    }));
    
    // 清除当前任务
    dispatch(setCurrentTask(null));
  }, [dispatch, t]);
  
  // 语言选项
  const languageOptions = [
    { value: 'zh-CN', label: '中文（普通话）' },
    { value: 'en-US', label: 'English (US)' },
    { value: 'ja-JP', label: '日本語' },
    { value: 'ko-KR', label: '한국어' },
  ];
  
  // 文件上传配置
  const uploadProps = {
    name: 'audio',
    multiple: false,
    accept: '.mp3,.wav,.m4a,.flac',
    beforeUpload: (file: File) => {
      // 检查文件类型
      const isAudio = file.type.startsWith('audio/') || 
        ['.mp3', '.wav', '.m4a', '.flac'].some(ext => file.name.toLowerCase().endsWith(ext));
      
      if (!isAudio) {
        message.error('请上传音频文件！');
        return false;
      }
      
      // 检查文件大小 (500MB)
      const isLt500M = file.size / 1024 / 1024 < 500;
      if (!isLt500M) {
        message.error('音频文件大小不能超过 500MB！');
        return false;
      }
      
      setSelectedFile(file);
      
      // 创建音频URL用于预览
      const url = URL.createObjectURL(file);
      setAudioUrl(url);
      
      return false; // 阻止自动上传
    },
    onRemove: () => {
      setSelectedFile(null);
      if (audioUrl) {
        URL.revokeObjectURL(audioUrl);
        setAudioUrl(null);
      }
    },
  };
  
  // 添加自定义词汇
  const handleAddVocabulary = () => {
    if (vocabularyInput.trim() && !customVocabulary.includes(vocabularyInput.trim())) {
      setCustomVocabulary([...customVocabulary, vocabularyInput.trim()]);
      setVocabularyInput('');
    }
  };
  
  // 删除自定义词汇
  const handleRemoveVocabulary = (word: string) => {
    setCustomVocabulary(customVocabulary.filter(w => w !== word));
  };
  
  // 开始转写
  const handleStartTranscription = async () => {
    if (!selectedFile) {
      message.error('请先选择音频文件！');
      return;
    }
    
    try {
      await dispatch(createSpeechToTextTask({
        file: selectedFile,
        language,
        speakerSeparation,
        customVocabulary,
      }));
    } catch (error) {
      console.error('Transcription error:', error);
    }
  };
  
  // 复制转写结果
  const handleCopyResult = () => {
    if (currentTask?.result?.transcript) {
      navigator.clipboard.writeText(currentTask.result.transcript);
      message.success('转写结果已复制到剪贴板');
    }
  };
  
  // 下载转写结果
  const handleDownloadResult = () => {
    if (currentTask?.result?.transcript) {
      const blob = new Blob([currentTask.result.transcript], { type: 'text/plain;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `transcript_${currentTask.id}.txt`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }
  };
  
  // 播放/暂停音频
  const handleToggleAudio = () => {
    const audio = document.getElementById('audio-preview') as HTMLAudioElement;
    if (audio) {
      if (isPlaying) {
        audio.pause();
      } else {
        audio.play();
      }
      setIsPlaying(!isPlaying);
    }
  };
  
  return (
    <div className="page-container">
      <Row gutter={[24, 24]}>
        {/* 左侧：文件上传和配置 */}
        <Col xs={24} lg={12}>
          <Card title="上传音频文件" style={{ marginBottom: '24px' }}>
            <Dragger {...uploadProps} style={{ marginBottom: '16px' }}>
              <p className="ant-upload-drag-icon">
                <AudioOutlined style={{ fontSize: '48px', color: '#1890ff' }} />
              </p>
              <p className="ant-upload-text">
                点击或拖拽音频文件到此区域上传
              </p>
              <p className="ant-upload-hint">
                支持格式：MP3, WAV, M4A, FLAC<br />
                最大文件大小：500MB
              </p>
            </Dragger>
            
            {selectedFile && (
              <Alert
                message={`已选择文件：${selectedFile.name}`}
                description={`文件大小：${(selectedFile.size / 1024 / 1024).toFixed(2)} MB`}
                type="success"
                showIcon
                action={
                  audioUrl && (
                    <Space>
                      <Button
                        size="small"
                        icon={isPlaying ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
                        onClick={handleToggleAudio}
                      >
                        {isPlaying ? '暂停' : '播放'}
                      </Button>
                    </Space>
                  )
                }
              />
            )}
            
            {audioUrl && (
              <audio
                id="audio-preview"
                src={audioUrl}
                style={{ display: 'none' }}
                onEnded={() => setIsPlaying(false)}
              />
            )}
          </Card>
          
          <Card title="转写设置">
            <Space direction="vertical" style={{ width: '100%' }} size="large">
              {/* 语言选择 */}
              <div>
                <Text strong>语言选择</Text>
                <Select
                  value={language}
                  onChange={setLanguage}
                  options={languageOptions}
                  style={{ width: '100%', marginTop: '8px' }}
                />
              </div>
              
              {/* 说话人分离 */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Text strong>说话人分离</Text>
                  <Switch
                    checked={speakerSeparation}
                    onChange={setSpeakerSeparation}
                  />
                </div>
                <Text type="secondary" style={{ fontSize: '12px' }}>
                  启用后将区分不同说话人的语音内容
                </Text>
              </div>
              
              {/* 自定义词汇 */}
              <div>
                <Text strong>自定义词汇</Text>
                <div style={{ marginTop: '8px' }}>
                  <Input.Group compact>
                    <Input
                      style={{ width: 'calc(100% - 80px)' }}
                      placeholder="输入专业术语或特殊词汇"
                      value={vocabularyInput}
                      onChange={(e) => setVocabularyInput(e.target.value)}
                      onPressEnter={handleAddVocabulary}
                    />
                    <Button type="primary" onClick={handleAddVocabulary}>
                      添加
                    </Button>
                  </Input.Group>
                </div>
                
                {customVocabulary.length > 0 && (
                  <div style={{ marginTop: '12px' }}>
                    <Space size={[8, 8]} wrap>
                      {customVocabulary.map((word) => (
                        <Tag
                          key={word}
                          closable
                          onClose={() => handleRemoveVocabulary(word)}
                        >
                          {word}
                        </Tag>
                      ))}
                    </Space>
                  </div>
                )}
                
                <Text type="secondary" style={{ fontSize: '12px', display: 'block', marginTop: '8px' }}>
                  添加专业术语可以提高识别准确率
                </Text>
              </div>
              
              {/* 开始转写按钮 */}
              <Button
                type="primary"
                size="large"
                block
                icon={<AudioOutlined />}
                onClick={handleStartTranscription}
                loading={isUploading || isProcessing}
                disabled={!selectedFile}
              >
                {isUploading ? '上传中...' : isProcessing ? '转写中...' : '开始转写'}
              </Button>
            </Space>
          </Card>
        </Col>
        
        {/* 右侧：转写结果 */}
        <Col xs={24} lg={12}>
          <Card 
            title="转写结果"
            extra={
              currentTask?.status === 'completed' && (
                <Space>
                  <Button
                    icon={<CopyOutlined />}
                    onClick={handleCopyResult}
                  >
                    复制
                  </Button>
                  <Button
                    icon={<DownloadOutlined />}
                    onClick={handleDownloadResult}
                  >
                    下载
                  </Button>
                </Space>
              )
            }
          >
            {!currentTask ? (
              <div style={{ textAlign: 'center', padding: '60px 20px' }}>
                <AudioOutlined style={{ fontSize: '64px', color: '#d9d9d9', marginBottom: '16px' }} />
                <Title level={4} type="secondary">
                  请上传音频文件开始转写
                </Title>
                <Paragraph type="secondary">
                  支持多种音频格式，转写结果将在此处显示
                </Paragraph>
              </div>
            ) : (
              <div>
                {/* 任务状态 */}
                <div style={{ marginBottom: '16px' }}>
                  <Space>
                    <Text strong>状态：</Text>
                    {currentTask.status === 'pending' && <Tag color="orange">等待中</Tag>}
                    {currentTask.status === 'processing' && <Tag color="blue">处理中</Tag>}
                    {currentTask.status === 'completed' && <Tag color="green">已完成</Tag>}
                    {currentTask.status === 'failed' && <Tag color="red">失败</Tag>}
                  </Space>
                </div>
                
                {/* 处理进度 */}
                {(currentTask.status === 'processing' || currentTask.status === 'pending') && (
                  <div style={{ marginBottom: '16px' }}>
                    <Progress 
                      percent={currentTask.status === 'processing' ? 50 : 10}
                      status="active"
                      strokeColor="#1890ff"
                    />
                    <Text type="secondary" style={{ fontSize: '12px' }}>
                      {currentTask.status === 'processing' ? '正在转写中，请稍候...' : '任务已提交，等待处理...'}
                    </Text>
                  </div>
                )}
                
                {/* 错误信息 */}
                {currentTask.status === 'failed' && currentTask.errorMessage && (
                  <Alert
                    message="转写失败"
                    description={currentTask.errorMessage}
                    type="error"
                    showIcon
                    style={{ marginBottom: '16px' }}
                  />
                )}
                
                {/* 调试信息 - 开发环境显示 */}
                {process.env.NODE_ENV === 'development' && currentTask.status === 'completed' && (
                  <div style={{ marginBottom: '16px' }}>
                    <Alert
                      message="调试信息"
                      description={
                        <pre style={{ fontSize: '12px', maxHeight: '200px', overflow: 'auto' }}>
                          {JSON.stringify(currentTask, null, 2)}
                        </pre>
                      }
                      type="info"
                      showIcon
                      closable
                    />
                  </div>
                )}

                {/* 转写结果 */}
                {currentTask.status === 'completed' && (
                  <div>
                    <Divider orientation="left">转写文本</Divider>
                    {currentTask.result?.transcript ? (
                      <div>
                        <TextArea
                          value={currentTask.result.transcript}
                          rows={12}
                          readOnly
                          style={{
                            fontSize: '14px',
                            lineHeight: '1.6',
                            backgroundColor: '#fafafa'
                          }}
                        />

                        {/* 转写信息 */}
                        <div style={{ marginTop: '16px' }}>
                          <Text type="secondary" style={{ fontSize: '12px' }}>
                            {currentTask.result.confidence && `置信度：${(currentTask.result.confidence * 100).toFixed(1)}% | `}
                            语言：{currentTask.result.language || language} |
                            处理时间：{currentTask.processingTime ? `${currentTask.processingTime}秒` : '未知'}
                          </Text>
                        </div>
                      </div>
                    ) : (
                      <Alert
                        message="转写完成但未获取到文本内容"
                        description="请检查音频文件是否包含可识别的语音内容"
                        type="warning"
                        showIcon
                      />
                    )}
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

export default SpeechToTextPage;
