import React, { useState, useRef, useEffect } from 'react';
import { Card, Input, Button, List, Avatar, Typography, Space, Spin, message } from 'antd';
import { SendOutlined, RobotOutlined, UserOutlined } from '@ant-design/icons';
import { useAppDispatch, useAppSelector } from '../store';
import { createGPTChatTask } from '../store/slices/taskSlice';

const { TextArea } = Input;
const { Text, Title } = Typography;

interface ChatMessage {
  id: string;
  type: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

const GPTChatPage: React.FC = () => {
  const dispatch = useAppDispatch();
  const { isLoading } = useAppSelector((state) => state.task);

  const [localLoading, setLocalLoading] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: '1',
      type: 'assistant',
      content: '您好！我是MediaGenie的AI助手，可以帮助您解答问题、分析内容、提供建议等。请告诉我您需要什么帮助？',
      timestamp: new Date().toLocaleTimeString()
    }
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [conversationId, setConversationId] = useState<string>('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async () => {
    if (!inputMessage.trim()) {
      message.warning('请输入消息内容');
      return;
    }

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      type: 'user',
      content: inputMessage,
      timestamp: new Date().toLocaleTimeString()
    };

    setMessages(prev => [...prev, userMessage]);
    const currentMessage = inputMessage;
    setInputMessage('');
    setLocalLoading(true);

    try {
      const result = await dispatch(createGPTChatTask({
        message: currentMessage,
        conversation_id: conversationId
      }));

      if (createGPTChatTask.fulfilled.match(result)) {
        const response = result.payload;
        
        const assistantMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          type: 'assistant',
          content: response.response,
          timestamp: new Date().toLocaleTimeString()
        };

        setMessages(prev => [...prev, assistantMessage]);
        
        if (response.conversation_id && !conversationId) {
          setConversationId(response.conversation_id);
        }
      } else {
        message.error('发送消息失败，请重试');
      }
    } catch (error) {
      console.error('GPT聊天错误:', error);
      message.error('发送消息失败，请重试');
    } finally {
      setLocalLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const clearChat = () => {
    setMessages([
      {
        id: '1',
        type: 'assistant',
        content: '您好！我是MediaGenie的AI助手，可以帮助您解答问题、分析内容、提供建议等。请告诉我您需要什么帮助？',
        timestamp: new Date().toLocaleTimeString()
      }
    ]);
    setConversationId('');
  };

  return (
    <div style={{ padding: '24px', height: '100vh', display: 'flex', flexDirection: 'column' }}>
      <div style={{ marginBottom: '24px' }}>
        <Title level={2}>GPT智能助手</Title>
        <Text type="secondary">
          与AI助手对话，获取智能回答和建议
        </Text>
      </div>

      <Card 
        style={{ 
          flex: 1, 
          display: 'flex', 
          flexDirection: 'column',
          marginBottom: '16px'
        }}
        bodyStyle={{ 
          flex: 1, 
          display: 'flex', 
          flexDirection: 'column',
          padding: '16px'
        }}
      >
        <div style={{ 
          flex: 1, 
          overflowY: 'auto', 
          marginBottom: '16px',
          border: '1px solid #f0f0f0',
          borderRadius: '8px',
          padding: '16px'
        }}>
          <List
            dataSource={messages}
            renderItem={(message) => (
              <List.Item style={{ border: 'none', padding: '8px 0' }}>
                <List.Item.Meta
                  avatar={
                    <Avatar 
                      icon={message.type === 'user' ? <UserOutlined /> : <RobotOutlined />}
                      style={{ 
                        backgroundColor: message.type === 'user' ? '#1890ff' : '#52c41a' 
                      }}
                    />
                  }
                  title={
                    <Space>
                      <Text strong>
                        {message.type === 'user' ? '您' : 'AI助手'}
                      </Text>
                      <Text type="secondary" style={{ fontSize: '12px' }}>
                        {message.timestamp}
                      </Text>
                    </Space>
                  }
                  description={
                    <div style={{ 
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                      marginTop: '8px'
                    }}>
                      {message.content}
                    </div>
                  }
                />
              </List.Item>
            )}
          />
          <div ref={messagesEndRef} />
        </div>

        <div style={{ display: 'flex', gap: '8px', alignItems: 'flex-end' }}>
          <TextArea
            value={inputMessage}
            onChange={(e) => setInputMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="输入您的消息... (按Enter发送，Shift+Enter换行)"
            autoSize={{ minRows: 1, maxRows: 4 }}
            style={{ flex: 1 }}
            disabled={localLoading || isLoading}
          />
          <Button
            type="primary"
            icon={<SendOutlined />}
            onClick={handleSendMessage}
            loading={localLoading || isLoading}
            disabled={!inputMessage.trim()}
          >
            发送
          </Button>
          <Button onClick={clearChat}>
            清空
          </Button>
        </div>
      </Card>

      {(localLoading || isLoading) && (
        <div style={{ textAlign: 'center', padding: '16px' }}>
          <Spin size="small" />
          <Text style={{ marginLeft: '8px' }}>AI正在思考中...</Text>
        </div>
      )}
    </div>
  );
};

export default GPTChatPage;
