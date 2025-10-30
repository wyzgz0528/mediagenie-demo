import React, { useState, useEffect } from 'react';
import { 
  Card, 
  Input, 
  Button, 
  Select, 
  Slider, 
  Switch, 
  Typography, 
  Space, 
  Alert,
  Divider,
  Row,
  Col,
  message,
  Progress,
  Tag
} from 'antd';
import { 
  SoundOutlined, 
  DownloadOutlined, 
  PlayCircleOutlined,
  PauseCircleOutlined,
  StopOutlined
} from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

import { useAppDispatch, useAppSelector } from '../store';
import { createTextToSpeechTask, setCurrentTask } from '../store/slices/taskSlice';
import { setPageInfo } from '../store/slices/uiSlice';

const { Title, Text, Paragraph } = Typography;
const { TextArea } = Input;

const TextToSpeechPage: React.FC = () => {
  const { t } = useTranslation();
  const dispatch = useAppDispatch();
  
  const { currentTask, isProcessing } = useAppSelector((state) => state.task);
  
  // 本地状态
  const [text, setText] = useState('');
  const [voice, setVoice] = useState('zh-CN-XiaoxiaoNeural');
  const [speed, setSpeed] = useState(1.0);
  const [pitch, setPitch] = useState(1.0);
  const [volume, setVolume] = useState(1.0);
  const [ssmlEnabled, setSsmlEnabled] = useState(false);
  const [isPlaying, setIsPlaying] = useState(false);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  
  useEffect(() => {
    // 设置页面信息
    dispatch(setPageInfo({
      title: t('textToSpeech.title'),
      description: t('textToSpeech.description') as string,
      breadcrumbs: [
        { title: t('nav.dashboard'), path: '/dashboard' },
        { title: t('nav.textToSpeech') }
      ]
    }));
    
    // 清除当前任务
    dispatch(setCurrentTask(null));
  }, [dispatch, t]);
  
  // 语音选项
  const voiceOptions = [
    { value: 'zh-CN-XiaoxiaoNeural', label: '晓晓 (女声, 温和)' },
    { value: 'zh-CN-YunxiNeural', label: '云希 (男声, 成熟)' },
    { value: 'zh-CN-YunyangNeural', label: '云扬 (男声, 专业)' },
    { value: 'zh-CN-XiaochenNeural', label: '晓辰 (女声, 甜美)' },
    { value: 'en-US-JennyNeural', label: 'Jenny (Female, US English)' },
    { value: 'en-US-GuyNeural', label: 'Guy (Male, US English)' },
    { value: 'ja-JP-NanamiNeural', label: 'Nanami (Female, Japanese)' },
    { value: 'ko-KR-SunHiNeural', label: 'SunHi (Female, Korean)' },
  ];
  
  // 计算字符数
  const characterCount = text.length;
  const maxCharacters = 5000; // 假设限制
  
  // 开始生成语音
  const handleGenerateSpeech = async () => {
    if (!text.trim()) {
      message.error('请输入要转换的文本！');
      return;
    }
    
    if (characterCount > maxCharacters) {
      message.error(`文本长度不能超过 ${maxCharacters} 个字符！`);
      return;
    }
    
    try {
      await dispatch(createTextToSpeechTask({
        text: text.trim(),
        voice,
        speed,
        pitch,
        volume,
        ssml: ssmlEnabled,
      }));
    } catch (error) {
      console.error('Text to speech error:', error);
    }
  };
  
  // 播放音频
  const handlePlayAudio = () => {
    if (currentTask?.result?.audioUrl) {
      const audio = document.getElementById('audio-player') as HTMLAudioElement;
      if (audio) {
        if (isPlaying) {
          audio.pause();
        } else {
          audio.play();
        }
        setIsPlaying(!isPlaying);
      }
    }
  };
  
  // 停止音频
  const handleStopAudio = () => {
    const audio = document.getElementById('audio-player') as HTMLAudioElement;
    if (audio) {
      audio.pause();
      audio.currentTime = 0;
      setIsPlaying(false);
    }
  };
  
  // 下载音频
  const handleDownloadAudio = () => {
    if (currentTask?.result?.audioUrl) {
      const a = document.createElement('a');
      a.href = currentTask.result.audioUrl;
      a.download = `speech_${currentTask.id}.mp3`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    }
  };
  
  // SSML示例
  const ssmlExample = `<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
  <voice name="zh-CN-XiaoxiaoNeural">
    欢迎使用 <emphasis level="strong">MediaGenie</emphasis> 文本转语音服务！
    <break time="500ms"/>
    我们提供高质量的语音合成功能。
  </voice>
</speak>`;
  
  return (
    <div className="page-container">
      <Row gutter={[24, 24]}>
        {/* 左侧：文本输入和设置 */}
        <Col xs={24} lg={12}>
          <Card title="文本输入" style={{ marginBottom: '24px' }}>
            <Space direction="vertical" style={{ width: '100%' }} size="large">
              {/* 文本输入区域 */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <Text strong>输入文本</Text>
                  <Text type={characterCount > maxCharacters ? 'danger' : 'secondary'} style={{ fontSize: '12px' }}>
                    {characterCount} / {maxCharacters} 字符
                  </Text>
                </div>
                <TextArea
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  placeholder={ssmlEnabled ? ssmlExample : "请输入要转换为语音的文本内容..."}
                  rows={8}
                  maxLength={maxCharacters}
                  showCount={false}
                />
              </div>
              
              {/* SSML支持 */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Text strong>SSML支持</Text>
                  <Switch
                    checked={ssmlEnabled}
                    onChange={setSsmlEnabled}
                  />
                </div>
                <Text type="secondary" style={{ fontSize: '12px' }}>
                  启用SSML可以精确控制语音的语调、停顿等
                </Text>
                {ssmlEnabled && (
                  <Button 
                    type="link" 
                    size="small" 
                    onClick={() => setText(ssmlExample)}
                    style={{ padding: 0, marginTop: '4px' }}
                  >
                    使用SSML示例
                  </Button>
                )}
              </div>
            </Space>
          </Card>
          
          <Card title="语音设置">
            <Space direction="vertical" style={{ width: '100%' }} size="large">
              {/* 语音选择 */}
              <div>
                <Text strong>语音选择</Text>
                <Select
                  value={voice}
                  onChange={setVoice}
                  options={voiceOptions}
                  style={{ width: '100%', marginTop: '8px' }}
                />
              </div>
              
              {/* 语速调节 */}
              <div>
                <Text strong>语速：{speed}x</Text>
                <Slider
                  min={0.5}
                  max={2.0}
                  step={0.1}
                  value={speed}
                  onChange={setSpeed}
                  marks={{
                    0.5: '0.5x',
                    1.0: '1.0x',
                    1.5: '1.5x',
                    2.0: '2.0x',
                  }}
                  style={{ marginTop: '8px' }}
                />
              </div>
              
              {/* 音调调节 */}
              <div>
                <Text strong>音调：{pitch}x</Text>
                <Slider
                  min={0.5}
                  max={2.0}
                  step={0.1}
                  value={pitch}
                  onChange={setPitch}
                  marks={{
                    0.5: '低',
                    1.0: '正常',
                    2.0: '高',
                  }}
                  style={{ marginTop: '8px' }}
                />
              </div>
              
              {/* 音量调节 */}
              <div>
                <Text strong>音量：{Math.round(volume * 100)}%</Text>
                <Slider
                  min={0.1}
                  max={1.0}
                  step={0.1}
                  value={volume}
                  onChange={setVolume}
                  marks={{
                    0.1: '10%',
                    0.5: '50%',
                    1.0: '100%',
                  }}
                  style={{ marginTop: '8px' }}
                />
              </div>
              
              {/* 生成语音按钮 */}
              <Button
                type="primary"
                size="large"
                block
                icon={<SoundOutlined />}
                onClick={handleGenerateSpeech}
                loading={isProcessing}
                disabled={!text.trim() || characterCount > maxCharacters}
              >
                {isProcessing ? '生成中...' : '生成语音'}
              </Button>
            </Space>
          </Card>
        </Col>
        
        {/* 右侧：语音结果 */}
        <Col xs={24} lg={12}>
          <Card 
            title="语音结果"
            extra={
              currentTask?.status === 'completed' && (
                <Space>
                  <Button
                    icon={isPlaying ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
                    onClick={handlePlayAudio}
                  >
                    {isPlaying ? '暂停' : '播放'}
                  </Button>
                  <Button
                    icon={<StopOutlined />}
                    onClick={handleStopAudio}
                    disabled={!isPlaying}
                  >
                    停止
                  </Button>
                  <Button
                    icon={<DownloadOutlined />}
                    onClick={handleDownloadAudio}
                  >
                    下载
                  </Button>
                </Space>
              )
            }
          >
            {!currentTask ? (
              <div style={{ textAlign: 'center', padding: '60px 20px' }}>
                <SoundOutlined style={{ fontSize: '64px', color: '#d9d9d9', marginBottom: '16px' }} />
                <Title level={4} type="secondary">
                  请输入文本开始生成语音
                </Title>
                <Paragraph type="secondary">
                  支持多种语音和语言，生成的音频将在此处播放
                </Paragraph>
              </div>
            ) : (
              <div>
                {/* 任务状态 */}
                <div style={{ marginBottom: '16px' }}>
                  <Space>
                    <Text strong>状态：</Text>
                    {currentTask.status === 'pending' && <Tag color="orange">等待中</Tag>}
                    {currentTask.status === 'processing' && <Tag color="blue">生成中</Tag>}
                    {currentTask.status === 'completed' && <Tag color="green">已完成</Tag>}
                    {currentTask.status === 'failed' && <Tag color="red">失败</Tag>}
                  </Space>
                </div>
                
                {/* 处理进度 */}
                {(currentTask.status === 'processing' || currentTask.status === 'pending') && (
                  <div style={{ marginBottom: '16px' }}>
                    <Progress 
                      percent={currentTask.status === 'processing' ? 60 : 20}
                      status="active"
                      strokeColor="#52c41a"
                    />
                    <Text type="secondary" style={{ fontSize: '12px' }}>
                      {currentTask.status === 'processing' ? '正在生成语音，请稍候...' : '任务已提交，等待处理...'}
                    </Text>
                  </div>
                )}
                
                {/* 错误信息 */}
                {currentTask.status === 'failed' && currentTask.errorMessage && (
                  <Alert
                    message="语音生成失败"
                    description={currentTask.errorMessage}
                    type="error"
                    showIcon
                    style={{ marginBottom: '16px' }}
                  />
                )}
                
                {/* 语音播放器 */}
                {currentTask.status === 'completed' && currentTask.result?.audioUrl && (
                  <div>
                    <Divider orientation="left">音频播放</Divider>
                    
                    <div style={{ 
                      background: '#f5f5f5', 
                      padding: '24px', 
                      borderRadius: '8px',
                      textAlign: 'center'
                    }}>
                      <SoundOutlined style={{ fontSize: '48px', color: '#52c41a', marginBottom: '16px' }} />
                      
                      <audio
                        id="audio-player"
                        src={currentTask.result.audioUrl}
                        onEnded={() => setIsPlaying(false)}
                        onPlay={() => setIsPlaying(true)}
                        onPause={() => setIsPlaying(false)}
                        controls
                        style={{ width: '100%', marginBottom: '16px' }}
                      />
                      
                      <Space size="large">
                        <Button
                          type="primary"
                          icon={isPlaying ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
                          onClick={handlePlayAudio}
                        >
                          {isPlaying ? '暂停播放' : '播放音频'}
                        </Button>
                        
                        <Button
                          icon={<DownloadOutlined />}
                          onClick={handleDownloadAudio}
                        >
                          下载音频
                        </Button>
                      </Space>
                    </div>
                    
                    {/* 生成信息 */}
                    <div style={{ marginTop: '16px' }}>
                      <Text type="secondary" style={{ fontSize: '12px' }}>
                        字符数：{characterCount} | 
                        语音：{voiceOptions.find(opt => opt.value === voice)?.label} | 
                        语速：{speed}x | 
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

export default TextToSpeechPage;
