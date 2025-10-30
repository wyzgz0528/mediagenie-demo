import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { message } from 'antd';

// 类型定义
export interface UsageSummary {
  speechMinutesUsed: number;
  speechMinutesLimit: number;
  ttsCharactersUsed: number;
  ttsCharactersLimit: number;
  imageRequestsUsed: number;
  imageRequestsLimit: number;
  apiCallsUsed: number;
  apiCallsLimit: number;
  currentPeriod: string;
}

export interface BillingHistory {
  id: string;
  date: string;
  amount: number;
  currency: string;
  status: 'paid' | 'pending' | 'failed';
  description: string;
  invoiceUrl?: string;
}

export interface Subscription {
  id: string;
  plan: 'free' | 'basic' | 'premium' | 'enterprise';
  status: 'active' | 'cancelled' | 'expired' | 'trial';
  currentPeriodStart: string;
  currentPeriodEnd: string;
  cancelAtPeriodEnd: boolean;
  trialEnd?: string;
  price: {
    amount: number;
    currency: string;
    interval: 'month' | 'year';
  };
}

export interface BillingState {
  usageSummary: UsageSummary | null;
  subscription: Subscription | null;
  billingHistory: BillingHistory[];
  isLoading: boolean;
  error: string | null;
  pagination: {
    current: number;
    pageSize: number;
    total: number;
  };
}

// 初始状态
const initialState: BillingState = {
  usageSummary: null,
  subscription: null,
  billingHistory: [],
  isLoading: false,
  error: null,
  pagination: {
    current: 1,
    pageSize: 10,
    total: 0,
  },
};

// 异步actions
export const fetchUsageSummary = createAsyncThunk(
  'billing/fetchUsageSummary',
  async (_, { rejectWithValue }) => {
    try {
      // 调用后端API获取使用情况摘要
      const response = await fetch('http://localhost:9001/api/billing/usage/summary');
      if (!response.ok) {
        throw new Error('Failed to fetch usage summary');
      }
      const data = await response.json();
      return data;
    } catch (error: any) {
      const errorMessage = error.message || '获取使用情况失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const fetchSubscription = createAsyncThunk(
  'billing/fetchSubscription',
  async (_, { rejectWithValue }) => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const mockSubscription: Subscription = {
        id: 'sub_1',
        plan: 'basic',
        status: 'active',
        currentPeriodStart: new Date().toISOString(),
        currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        cancelAtPeriodEnd: false,
        price: {
          amount: 99.99,
          currency: 'CNY',
          interval: 'month',
        },
      };

      return mockSubscription;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '获取订阅信息失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const fetchBillingHistory = createAsyncThunk(
  'billing/fetchBillingHistory',
  async (params: { page?: number; pageSize?: number } = {}, { rejectWithValue }) => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const mockHistory: BillingHistory[] = [
        {
          id: 'inv_1',
          date: '2024-01-15',
          amount: 99.99,
          currency: 'CNY',
          status: 'paid',
          description: 'MediaGenie 基础版 - 月度订阅',
          invoiceUrl: '/invoices/inv_1.pdf',
        },
        {
          id: 'inv_2',
          date: '2023-12-15',
          amount: 99.99,
          currency: 'CNY',
          status: 'paid',
          description: 'MediaGenie 基础版 - 月度订阅',
          invoiceUrl: '/invoices/inv_2.pdf',
        },
      ];

      return {
        data: mockHistory,
        pagination: {
          current: params.page || 1,
          pageSize: params.pageSize || 10,
          total: mockHistory.length,
        },
      };
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '获取账单历史失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const updateSubscription = createAsyncThunk(
  'billing/updateSubscription',
  async (data: { plan: string; interval: 'month' | 'year' }, { rejectWithValue }) => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      message.success('订阅计划更新成功');
      return data;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '更新订阅失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

export const cancelSubscription = createAsyncThunk(
  'billing/cancelSubscription',
  async (_, { rejectWithValue }) => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      message.success('订阅已取消，将在当前计费周期结束时生效');
      return true;
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || '取消订阅失败';
      message.error(errorMessage);
      return rejectWithValue(errorMessage);
    }
  }
);

// Slice
const billingSlice = createSlice({
  name: 'billing',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setPagination: (state, action: PayloadAction<Partial<BillingState['pagination']>>) => {
      state.pagination = { ...state.pagination, ...action.payload };
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch Usage Summary
      .addCase(fetchUsageSummary.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchUsageSummary.fulfilled, (state, action) => {
        state.isLoading = false;
        state.usageSummary = action.payload;
      })
      .addCase(fetchUsageSummary.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      
      // Fetch Subscription
      .addCase(fetchSubscription.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchSubscription.fulfilled, (state, action) => {
        state.isLoading = false;
        state.subscription = action.payload;
      })
      .addCase(fetchSubscription.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      
      // Fetch Billing History
      .addCase(fetchBillingHistory.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchBillingHistory.fulfilled, (state, action) => {
        state.isLoading = false;
        state.billingHistory = action.payload.data;
        state.pagination = action.payload.pagination;
      })
      .addCase(fetchBillingHistory.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      
      // Update Subscription
      .addCase(updateSubscription.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(updateSubscription.fulfilled, (state) => {
        state.isLoading = false;
      })
      .addCase(updateSubscription.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      
      // Cancel Subscription
      .addCase(cancelSubscription.fulfilled, (state) => {
        if (state.subscription) {
          state.subscription.cancelAtPeriodEnd = true;
        }
      });
  },
});

export const {
  clearError,
  setPagination,
} = billingSlice.actions;

export default billingSlice.reducer;
