import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import { message } from 'antd';
import { getValidAccessToken } from './authService';

// API基础配置 - 动态获取后端地址
// 生产环境：使用相对路径（前后端同域）或环境变量
// 开发环境：使用 localhost:9001
const getMediaServiceURL = (): string => {
  // 优先使用环境变量
  if (process.env.REACT_APP_MEDIA_SERVICE_URL) {
    return process.env.REACT_APP_MEDIA_SERVICE_URL;
  }

  // 生产环境：使用相对路径（假设前后端在同一域名下）
  if (process.env.NODE_ENV === 'production') {
    // 如果后端在 /api 路径下
    return window.location.origin;
  }

  // 开发环境：使用 localhost
  return 'http://localhost:9001';
};

const MEDIA_SERVICE_URL = getMediaServiceURL();

console.log('🔧 API Base URL:', MEDIA_SERVICE_URL);

// 创建媒体服务axios实例
const mediaClient: AxiosInstance = axios.create({
  baseURL: MEDIA_SERVICE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器 - 添加 JWT 令牌
mediaClient.interceptors.request.use(
  async (config: InternalAxiosRequestConfig) => {
    // 排除静态资源请求（favicon, 图片等）
    const url = config.url || '';
    if (url.includes('favicon') || url.includes('.png') || url.includes('.ico') || url.includes('.jpg') || url.includes('.jpeg')) {
      return config;
    }

    try {
      // 获取访问令牌
      const token = await getValidAccessToken();

      if (token) {
        // 添加 Authorization 头
        config.headers.Authorization = `Bearer ${token}`;
        console.log('✅ 已添加 JWT 令牌到请求头');
      }
    } catch (error) {
      console.warn('⚠️ 无法获取访问令牌:', error);
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器
mediaClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const errorMessage = error.response?.data?.message ||
                        error.response?.data?.error ||
                        error.message ||
                        '请求失败';

    // 处理 401 未授权错误
    if (error.response?.status === 401) {
      console.warn('⚠️ 认证令牌已过期，请重新登录');
      // 清除本地存储的令牌
      localStorage.removeItem('accessToken');
      localStorage.removeItem('idToken');
      // 可以在这里触发重新登录流程
    }

    message.error(errorMessage);
    return Promise.reject(error);
  }
);

// 媒体服务API
export const mediaAPI = {
  // 语音转文本
  speechToText: (audioFile: File, language?: string) => {
    const formData = new FormData();
    formData.append('file', audioFile);
    if (language) {
      formData.append('language', language);
    }
  return mediaClient.post('/speech/speech-to-text-file', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },

  // 文本转语音
  textToSpeech: (text: string, voice?: string) =>
  mediaClient.post('/speech/text-to-speech', { text, voice }, {
      responseType: 'blob',
    }),

  // 图像分析
  analyzeImage: (imageFile: File) => {
    const formData = new FormData();
    formData.append('file', imageFile);
  return mediaClient.post('/vision/image-analysis-file', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },

  // GPT聊天
  gptChat: (message: string, conversation_id?: string) =>
  mediaClient.post('/gpt/chat', { message, conversation_id }),

  // 健康检查
  healthCheck: () =>
  mediaClient.get('/health'),
};

// 任务API
export const taskAPI = {
  getTasks: (params?: any) => mediaClient.get('/media/tasks', { params }),
  getTask: (taskId: string) => mediaClient.get(`/media/tasks/${taskId}`),
  getTaskById: (taskId: string) => mediaClient.get(`/media/tasks/${taskId}`),
  deleteTask: (taskId: string) => mediaClient.delete(`/media/tasks/${taskId}`),
  deleteTasks: (taskIds: string[]) => mediaClient.delete('/media/tasks/batch', { data: { taskIds } }),

  // 创建任务的API方法
  createSpeechToTextTask: (formData: FormData) =>
    mediaClient.post('/speech/speech-to-text-file', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  createTextToSpeechTask: (data: { text: string; voice?: string; format?: string }) =>
    mediaClient.post('/speech/text-to-speech', data, {
      responseType: 'blob',
    }),

  createImageAnalysisTask: (formData: FormData) =>
    mediaClient.post('/vision/image-analysis-file', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  createGPTChatTask: (data: { message: string; conversation_id?: string }) =>
    mediaClient.post('/gpt/chat', data),

  retryTask: (taskId: string) => mediaClient.post(`/media/tasks/${taskId}/retry`),
};

export default mediaClient;