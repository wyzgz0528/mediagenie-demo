import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { message } from 'antd';
import { taskAPI } from '../../services/api';

// 类型定义
export interface Task {
  id: string;
  userId: string;
  taskType: 'speech_to_text' | 'text_to_speech' | 'image_analysis' | 'gpt_chat';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  priority: number;
  inputFileUrl?: string;
  inputFileName?: string;
  inputFileSize?: number;
  outputFileUrl?: string;
  outputFileName?: string;
  outputFileSize?: number;
  parameters: Record<string, any>;
  result?: Record<string, any>;
  errorMessage?: string;
  processingTime?: number;
  createdAt: string;
  startedAt?: string;
  completedAt?: string;
  updatedAt: string;
  progress?: number;
}

export interface TaskState {
  tasks: Task[];
  currentTask: Task | null;
  isLoading: boolean;
  isUploading: boolean;
  isProcessing: boolean;
  error: string | null;
  pagination: {
    current: number;
    pageSize: number;
    total: number;
  };
  filters: {
    taskType?: string;
    status?: string;
    dateRange?: [string, string];
  };
}

// 初始状态
const initialState: TaskState = {
  tasks: [],
  currentTask: null,
  isLoading: false,
  isUploading: false,
  isProcessing: false,
  error: null,
  pagination: {
    current: 1,
    pageSize: 10,
    total: 0,
  },
  filters: {},
};

// 异步actions
export const fetchTasks = createAsyncThunk(
  'task/fetchTasks',
  async (params: {
    page?: number;
    pageSize?: number;
    taskType?: string;
    status?: string;
    dateRange?: [string, string];
  } = {}, { rejectWithValue }) => {
    try {
      const response = await taskAPI.getTasks(params);
      return response.data;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '获取任务列表失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const fetchTaskById = createAsyncThunk(
  'task/fetchTaskById',
  async (taskId: string, { rejectWithValue }) => {
    try {
      const response = await taskAPI.getTaskById(taskId);
      return response.data;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '获取任务详情失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const createSpeechToTextTask = createAsyncThunk(
  'task/createSpeechToTextTask',
  async (payload: {
    file: File;
    language: string;
    speakerSeparation?: boolean;
    customVocabulary?: string[];
  }, { rejectWithValue }) => {
    try {
      const formData = new FormData();
      formData.append('file', payload.file);
      formData.append('language', payload.language);
      if (payload.speakerSeparation) {
        formData.append('speakerSeparation', 'true');
      }
      if (payload.customVocabulary && payload.customVocabulary.length > 0) {
        formData.append('customVocabulary', JSON.stringify(payload.customVocabulary));
      }

      const response = await taskAPI.createSpeechToTextTask(formData);
      message.success('语音转写任务创建成功');

      const data = response.data || {};
      const backendTask = data.task || data;

      const fallbackId = Date.now().toString();
      const transcript = backendTask?.result?.transcript || backendTask?.transcript || backendTask?.text || '';

      const task: Task = {
        id: backendTask?.id || backendTask?.task_id || fallbackId,
        userId: backendTask?.userId || 'current-user',
        taskType: backendTask?.taskType || 'speech_to_text',
        status: backendTask?.status || 'completed',
        priority: backendTask?.priority || 1,
        inputFileName: backendTask?.inputFileName || payload.file.name,
        inputFileSize: backendTask?.inputFileSize || payload.file.size,
        parameters: backendTask?.parameters || {
          language: payload.language,
          speakerSeparation: !!payload.speakerSeparation,
          customVocabulary: payload.customVocabulary || [],
        },
        result: backendTask?.result || {
          transcript,
          confidence: backendTask?.confidence ?? null,
          language: backendTask?.language || payload.language,
          raw: backendTask,
        },
        errorMessage: backendTask?.errorMessage ?? undefined,
        processingTime: backendTask?.processingTime ?? undefined,
        createdAt: backendTask?.createdAt || new Date().toISOString(),
        startedAt: backendTask?.startedAt ?? undefined,
        completedAt: backendTask?.completedAt || new Date().toISOString(),
        updatedAt: backendTask?.updatedAt || new Date().toISOString(),
        outputFileUrl: backendTask?.outputFileUrl,
        outputFileName: backendTask?.outputFileName,
        inputFileUrl: backendTask?.inputFileUrl,
        outputFileSize: backendTask?.outputFileSize,
        progress: backendTask?.progress,
      } as Task;

      return task;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '创建语音转写任务失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const createTextToSpeechTask = createAsyncThunk(
  'task/createTextToSpeechTask',
  async (data: {
    text: string;
    voice: string;
    speed?: number;
    pitch?: number;
    volume?: number;
    ssml?: boolean;
  }, { rejectWithValue }) => {
    try {
      const response = await taskAPI.createTextToSpeechTask(data);

      // 如果响应是blob（音频文件），创建URL
      let audioUrl = null;
      if (response.data instanceof Blob) {
        audioUrl = URL.createObjectURL(response.data);
      }

      // 创建任务对象
      const task: Task = {
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        userId: 'current-user', // 应该从认证状态获取
        taskType: 'text_to_speech',
        status: 'completed',
        priority: 1,
        parameters: data,
        result: {
          audioUrl,
          audioSize: response.data instanceof Blob ? response.data.size : 0,
          text: data.text,
          voice: data.voice
        },
        createdAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      message.success('文本转语音任务完成');
      return task;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '创建文本转语音任务失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const createImageAnalysisTask = createAsyncThunk(
  'task/createImageAnalysisTask',
  async (payload: {
    file: File;
    analysisTypes: string[];
  }, { rejectWithValue }) => {
    try {
      const formData = new FormData();
      formData.append('file', payload.file);

      const featureMap: Record<string, string> = {
        ocr: 'text',
        objects: 'objects',
        faces: 'faces',
        tags: 'tags',
      };
      const features = payload.analysisTypes.map((type) => featureMap[type] || type);

      formData.append('features', features.join(','));

      const response = await taskAPI.createImageAnalysisTask(formData);
      message.success('图像分析任务创建成功');

      const data = response.data || {};
      const backendTask = data.task || data;
      const fallbackId = Date.now().toString();

      const task: Task = {
        id: backendTask?.id || backendTask?.task_id || fallbackId,
        userId: backendTask?.userId || 'current-user',
        taskType: backendTask?.taskType || 'image_analysis',
        status: backendTask?.status || 'completed',
        priority: backendTask?.priority || 1,
        inputFileName: backendTask?.inputFileName || payload.file.name,
        inputFileSize: backendTask?.inputFileSize || payload.file.size,
        parameters: backendTask?.parameters || {
          analysisTypes: payload.analysisTypes,
        },
        result: backendTask?.result || {
          ocr: data.text
            ? {
                text: data.text.full_text || data.text.text || '',
                lines: data.text.lines || [],
              }
            : undefined,
          objects: data.objects || [],
          faces: data.faces || [],
          tags: data.tags || [],
          description: data.description || null,
          categories: data.categories || [],
          raw: data,
        },
        errorMessage: backendTask?.errorMessage ?? undefined,
        processingTime: backendTask?.processingTime ?? undefined,
        createdAt: backendTask?.createdAt || new Date().toISOString(),
        startedAt: backendTask?.startedAt ?? undefined,
        completedAt: backendTask?.completedAt || new Date().toISOString(),
        updatedAt: backendTask?.updatedAt || new Date().toISOString(),
        inputFileUrl: backendTask?.inputFileUrl,
        outputFileUrl: backendTask?.outputFileUrl,
        outputFileName: backendTask?.outputFileName,
        progress: backendTask?.progress,
      } as Task;

      return task;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '创建图像分析任务失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const createGPTChatTask = createAsyncThunk(
  'task/createGPTChatTask',
  async (data: {
    message: string;
    conversation_id?: string;
  }, { rejectWithValue }) => {
    try {
      const response = await taskAPI.createGPTChatTask(data);
      return response.data;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'GPT聊天失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const retryTask = createAsyncThunk(
  'task/retryTask',
  async (taskId: string, { rejectWithValue }) => {
    try {
      const response = await taskAPI.retryTask(taskId);
      message.success('任务重试成功');
      return response.data;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '任务重试失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const deleteTask = createAsyncThunk(
  'task/deleteTask',
  async (taskId: string, { rejectWithValue }) => {
    try {
      await taskAPI.deleteTask(taskId);
      message.success('任务删除成功');
      return taskId;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '任务删除失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

// Slice
const taskSlice = createSlice({
  name: 'task',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setCurrentTask: (state, action: PayloadAction<Task | null>) => {
      state.currentTask = action.payload;
    },
    updateTaskStatus: (state, action: PayloadAction<{ taskId: string; status: Task['status']; result?: any }>) => {
      const { taskId, status, result } = action.payload;
      const task = state.tasks.find(t => t.id === taskId);
      if (task) {
        task.status = status;
        if (result) {
          task.result = result;
        }
        if (status === 'completed') {
          task.completedAt = new Date().toISOString();
        }
      }
      if (state.currentTask && state.currentTask.id === taskId) {
        state.currentTask.status = status;
        if (result) {
          state.currentTask.result = result;
        }
        if (status === 'completed') {
          state.currentTask.completedAt = new Date().toISOString();
        }
      }
    },
    setPagination: (state, action: PayloadAction<Partial<TaskState['pagination']>>) => {
      state.pagination = { ...state.pagination, ...action.payload };
    },
    setFilters: (state, action: PayloadAction<TaskState['filters']>) => {
      state.filters = action.payload;
    },
    clearFilters: (state) => {
      state.filters = {};
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch Tasks
      .addCase(fetchTasks.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchTasks.fulfilled, (state, action) => {
        state.isLoading = false;

        const payload = action.payload ?? {};
        const tasks = Array.isArray(payload)
          ? payload
          : Array.isArray(payload.tasks)
            ? payload.tasks
            : [];

        const pagination = payload.pagination && typeof payload.pagination === 'object'
          ? payload.pagination
          : {
              current: state.pagination?.current || 1,
              pageSize: state.pagination?.pageSize || 10,
              total: tasks.length,
            };

        state.tasks = tasks;
        state.pagination = {
          current: pagination.current ?? (state.pagination?.current || 1),
          pageSize: pagination.pageSize ?? (state.pagination?.pageSize || 10),
          total: pagination.total ?? tasks.length,
        };
      })
      .addCase(fetchTasks.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      
      // Fetch Task By ID
      .addCase(fetchTaskById.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchTaskById.fulfilled, (state, action) => {
        state.isLoading = false;
        state.currentTask = action.payload;
      })
      .addCase(fetchTaskById.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      
      // Create Speech to Text Task
      .addCase(createSpeechToTextTask.pending, (state) => {
        state.isUploading = true;
        state.isProcessing = true;
        state.error = null;
      })
      .addCase(createSpeechToTextTask.fulfilled, (state, action) => {
        state.isUploading = false;
        state.isProcessing = false;
        state.currentTask = action.payload;
        state.tasks.unshift(action.payload);
      })
      .addCase(createSpeechToTextTask.rejected, (state, action) => {
        state.isUploading = false;
        state.isProcessing = false;
        state.error = action.payload as string;
      })
      
      // Create Text to Speech Task
      .addCase(createTextToSpeechTask.pending, (state) => {
        state.isProcessing = true;
        state.error = null;
      })
      .addCase(createTextToSpeechTask.fulfilled, (state, action) => {
        state.isProcessing = false;
        state.currentTask = action.payload;
        state.tasks.unshift(action.payload);
      })
      .addCase(createTextToSpeechTask.rejected, (state, action) => {
        state.isProcessing = false;
        state.error = action.payload as string;
      })
      
      // Create Image Analysis Task
      .addCase(createImageAnalysisTask.pending, (state) => {
        state.isUploading = true;
        state.isProcessing = true;
        state.error = null;
      })
      .addCase(createImageAnalysisTask.fulfilled, (state, action) => {
        state.isUploading = false;
        state.isProcessing = false;
        state.currentTask = action.payload;
        state.tasks.unshift(action.payload);
      })
      .addCase(createImageAnalysisTask.rejected, (state, action) => {
        state.isUploading = false;
        state.isProcessing = false;
        state.error = action.payload as string;
      })

      // Create GPT Chat Task
      .addCase(createGPTChatTask.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(createGPTChatTask.fulfilled, (state) => {
        state.isLoading = false;
      })
      .addCase(createGPTChatTask.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      
      // Retry Task
      .addCase(retryTask.fulfilled, (state, action) => {
        const updatedTask = action.payload;
        const index = state.tasks.findIndex(t => t.id === updatedTask.id);
        if (index !== -1) {
          state.tasks[index] = updatedTask;
        }
        if (state.currentTask && state.currentTask.id === updatedTask.id) {
          state.currentTask = updatedTask;
        }
      })
      
      // Delete Task
      .addCase(deleteTask.fulfilled, (state, action) => {
        const taskId = action.payload;
        state.tasks = state.tasks.filter(t => t.id !== taskId);
        if (state.currentTask && state.currentTask.id === taskId) {
          state.currentTask = null;
        }
        state.pagination.total = Math.max(0, state.pagination.total - 1);
      });
  },
});

export const {
  clearError,
  setCurrentTask,
  updateTaskStatus,
  setPagination,
  setFilters,
  clearFilters,
} = taskSlice.actions;

export default taskSlice.reducer;
