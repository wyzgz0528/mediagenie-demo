import React, { useEffect, useState } from 'react';
import { 
  Card, 
  Table, 
  Button, 
  Tag, 
  Space, 
  Input, 
  Select, 
  DatePicker, 
  Typography,
  Popconfirm,
  message,
  Modal,
  Descriptions,
  Divider
} from 'antd';
import { 
  HistoryOutlined, 
  DownloadOutlined, 
  DeleteOutlined,
  EyeOutlined,
  SearchOutlined,
  ReloadOutlined
} from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import type { ColumnsType } from 'antd/es/table';
import dayjs from 'dayjs';

import { useAppDispatch, useAppSelector } from '../store';
import { fetchTasks, deleteTask } from '../store/slices/taskSlice';
import { setPageInfo } from '../store/slices/uiSlice';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

interface TaskRecord {
  id: string;
  taskType: string;
  inputFileName: string;
  status: string;
  createdAt: string;
  completedAt?: string;
  processingTime?: number;
  errorMessage?: string;
  result?: any;
}

const HistoryPage: React.FC = () => {
  const { t } = useTranslation();
  const dispatch = useAppDispatch();
  
  const { tasks, isLoading } = useAppSelector((state) => state.task);
  const total = tasks?.length || 0;
  
  // 本地状态
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [searchText, setSearchText] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [typeFilter, setTypeFilter] = useState<string>('');
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);
  const [selectedTask, setSelectedTask] = useState<TaskRecord | null>(null);
  const [detailModalVisible, setDetailModalVisible] = useState(false);
  
  useEffect(() => {
    // 设置页面信息
    dispatch(setPageInfo({
      title: t('history.title'),
      description: t('history.description') as string,
      breadcrumbs: [
        { title: t('nav.dashboard'), path: '/dashboard' },
        { title: t('nav.history') }
      ]
    }));
    
    // 获取任务列表
    fetchTaskList();
  }, [dispatch, t, currentPage, pageSize]);
  
  // 获取任务列表
  const fetchTaskList = () => {
    const params: any = {
      page: currentPage,
      pageSize,
    };
    
    if (searchText) params.search = searchText;
    if (statusFilter) params.status = statusFilter;
    if (typeFilter) params.taskType = typeFilter;
    if (dateRange) {
      params.startDate = dateRange[0].format('YYYY-MM-DD');
      params.endDate = dateRange[1].format('YYYY-MM-DD');
    }
    
    dispatch(fetchTasks(params));
  };
  
  // 搜索处理
  const handleSearch = () => {
    setCurrentPage(1);
    fetchTaskList();
  };
  
  // 重置筛选
  const handleReset = () => {
    setSearchText('');
    setStatusFilter('');
    setTypeFilter('');
    setDateRange(null);
    setCurrentPage(1);
    setTimeout(fetchTaskList, 100);
  };
  
  // 删除任务
  const handleDeleteTask = async (taskId: string) => {
    try {
      await dispatch(deleteTask(taskId));
      message.success('任务删除成功');
      fetchTaskList();
    } catch (error) {
      message.error('任务删除失败');
    }
  };
  
  // 查看任务详情
  const handleViewDetail = (task: TaskRecord) => {
    setSelectedTask(task);
    setDetailModalVisible(true);
  };
  
  // 下载结果
  const handleDownloadResult = (task: TaskRecord) => {
    if (task.result) {
      let content = '';
      let filename = '';
      let mimeType = '';
      
      switch (task.taskType) {
        case 'speech_to_text':
          content = task.result.transcript || '';
          filename = `transcript_${task.id}.txt`;
          mimeType = 'text/plain;charset=utf-8';
          break;
        case 'text_to_speech':
          if (task.result.audioUrl) {
            // 直接下载音频文件
            const a = document.createElement('a');
            a.href = task.result.audioUrl;
            a.download = `speech_${task.id}.mp3`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            return;
          }
          break;
        case 'image_analysis':
          content = JSON.stringify(task.result, null, 2);
          filename = `analysis_${task.id}.json`;
          mimeType = 'application/json;charset=utf-8';
          break;
        default:
          message.error('不支持的任务类型');
          return;
      }
      
      if (content) {
        const blob = new Blob([content], { type: mimeType });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
    }
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
  
  // 获取状态标签
  const getStatusTag = (status: string) => {
    const statusMap = {
      pending: { color: 'orange', text: '等待中' },
      processing: { color: 'blue', text: '处理中' },
      completed: { color: 'green', text: '已完成' },
      failed: { color: 'red', text: '失败' },
    };
    
    const config = statusMap[status as keyof typeof statusMap] || { color: 'default', text: status };
    return <Tag color={config.color}>{config.text}</Tag>;
  };
  
  // 表格列配置
  const columns: ColumnsType<TaskRecord> = [
    {
      title: '任务类型',
      dataIndex: 'taskType',
      key: 'taskType',
      width: 120,
      render: (taskType: string) => getTaskTypeName(taskType),
    },
    {
      title: '文件名',
      dataIndex: 'inputFileName',
      key: 'inputFileName',
      ellipsis: true,
      render: (fileName: string) => fileName || '未知文件',
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (status: string) => getStatusTag(status),
    },
    {
      title: '创建时间',
      dataIndex: 'createdAt',
      key: 'createdAt',
      width: 160,
      render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm'),
    },
    {
      title: '处理时间',
      dataIndex: 'processingTime',
      key: 'processingTime',
      width: 100,
      render: (time: number) => time ? `${time}秒` : '-',
    },
    {
      title: '操作',
      key: 'actions',
      width: 180,
      render: (_, record: TaskRecord) => (
        <Space size="small">
          <Button
            type="link"
            size="small"
            icon={<EyeOutlined />}
            onClick={() => handleViewDetail(record)}
          >
            详情
          </Button>
          
          {record.status === 'completed' && record.result && (
            <Button
              type="link"
              size="small"
              icon={<DownloadOutlined />}
              onClick={() => handleDownloadResult(record)}
            >
              下载
            </Button>
          )}
          
          <Popconfirm
            title="确定要删除这个任务吗？"
            onConfirm={() => handleDeleteTask(record.id)}
            okText="确定"
            cancelText="取消"
          >
            <Button
              type="link"
              size="small"
              danger
              icon={<DeleteOutlined />}
            >
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];
  
  return (
    <div className="page-container">
      <Card>
        {/* 筛选区域 */}
        <div style={{ marginBottom: '16px' }}>
          <Space wrap>
            <Input
              placeholder="搜索文件名"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              onPressEnter={handleSearch}
              style={{ width: 200 }}
              prefix={<SearchOutlined />}
            />
            
            <Select
              placeholder="任务类型"
              value={typeFilter}
              onChange={setTypeFilter}
              style={{ width: 120 }}
              allowClear
            >
              <Select.Option value="speech_to_text">语音转写</Select.Option>
              <Select.Option value="text_to_speech">文本转语音</Select.Option>
              <Select.Option value="image_analysis">图像分析</Select.Option>
            </Select>
            
            <Select
              placeholder="状态"
              value={statusFilter}
              onChange={setStatusFilter}
              style={{ width: 100 }}
              allowClear
            >
              <Select.Option value="pending">等待中</Select.Option>
              <Select.Option value="processing">处理中</Select.Option>
              <Select.Option value="completed">已完成</Select.Option>
              <Select.Option value="failed">失败</Select.Option>
            </Select>
            
            <RangePicker
              value={dateRange}
              onChange={(dates) => setDateRange(dates as [any, any] | null)}
              format="YYYY-MM-DD"
              placeholder={['开始日期', '结束日期']}
            />
            
            <Button type="primary" icon={<SearchOutlined />} onClick={handleSearch}>
              搜索
            </Button>
            
            <Button icon={<ReloadOutlined />} onClick={handleReset}>
              重置
            </Button>
          </Space>
        </div>
        
        {/* 任务列表表格 */}
        <Table
          columns={columns as any}
          dataSource={tasks}
          rowKey="id"
          loading={isLoading}
          pagination={{
            current: currentPage,
            pageSize,
            total,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total, range) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`,
            onChange: (page, size) => {
              setCurrentPage(page);
              setPageSize(size || 10);
            },
          }}
        />
      </Card>
      
      {/* 任务详情模态框 */}
      <Modal
        title="任务详情"
        open={detailModalVisible}
        onCancel={() => setDetailModalVisible(false)}
        footer={[
          <Button key="close" onClick={() => setDetailModalVisible(false)}>
            关闭
          </Button>,
          selectedTask?.status === 'completed' && selectedTask?.result && (
            <Button
              key="download"
              type="primary"
              icon={<DownloadOutlined />}
              onClick={() => {
                if (selectedTask) {
                  handleDownloadResult(selectedTask);
                }
              }}
            >
              下载结果
            </Button>
          ),
        ]}
        width={800}
      >
        {selectedTask && (
          <div>
            <Descriptions column={2} bordered size="small">
              <Descriptions.Item label="任务ID">{selectedTask.id}</Descriptions.Item>
              <Descriptions.Item label="任务类型">{getTaskTypeName(selectedTask.taskType)}</Descriptions.Item>
              <Descriptions.Item label="文件名">{selectedTask.inputFileName || '未知文件'}</Descriptions.Item>
              <Descriptions.Item label="状态">{getStatusTag(selectedTask.status)}</Descriptions.Item>
              <Descriptions.Item label="创建时间">
                {dayjs(selectedTask.createdAt).format('YYYY-MM-DD HH:mm:ss')}
              </Descriptions.Item>
              <Descriptions.Item label="完成时间">
                {selectedTask.completedAt ? dayjs(selectedTask.completedAt).format('YYYY-MM-DD HH:mm:ss') : '-'}
              </Descriptions.Item>
              <Descriptions.Item label="处理时间">
                {selectedTask.processingTime ? `${selectedTask.processingTime}秒` : '-'}
              </Descriptions.Item>
            </Descriptions>
            
            {selectedTask.errorMessage && (
              <div style={{ marginTop: '16px' }}>
                <Divider orientation="left">错误信息</Divider>
                <Text type="danger">{selectedTask.errorMessage}</Text>
              </div>
            )}
            
            {selectedTask.result && (
              <div style={{ marginTop: '16px' }}>
                <Divider orientation="left">处理结果</Divider>
                <div style={{ 
                  background: '#fafafa', 
                  padding: '12px', 
                  borderRadius: '6px',
                  maxHeight: '300px',
                  overflow: 'auto'
                }}>
                  <pre style={{ margin: 0, fontSize: '12px' }}>
                    {JSON.stringify(selectedTask.result, null, 2)}
                  </pre>
                </div>
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
};

export default HistoryPage;
