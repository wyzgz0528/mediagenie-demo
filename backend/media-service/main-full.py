#!/usr/bin/env python3
"""
MediaGenie Media Processing Service
FastAPI服务，提供语音转写、文本转语音、图像分析等功能
"""

import os
import time
import logging
from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv
from openai import AzureOpenAI
import io
import base64
import logging
import uuid
import json
import math
import struct
import wave
from typing import Optional, Dict, Any, List, TYPE_CHECKING, Tuple
from datetime import datetime
from enum import Enum

from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 数据库和存储imports
try:
    import asyncpg
    import redis.asyncio as redis
    DATABASE_AVAILABLE = True
except ImportError:
    DATABASE_AVAILABLE = False
    print("Warning: Database libraries not installed. Using in-memory storage.")

# Azure服务imports
try:
    from azure.storage.blob import BlobServiceClient
    from azure.cognitiveservices.vision.computervision import ComputerVisionClient
    from azure.cognitiveservices.vision.computervision.models import OperationStatusCodes
    from msrest.authentication import CognitiveServicesCredentials
    import azure.cognitiveservices.speech as speechsdk
    AZURE_AVAILABLE = True
except ImportError:
    AZURE_AVAILABLE = False
    print("Warning: Azure SDK libraries not installed. Using mock services.")


# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/media-service.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# 确保日志目录存在
os.makedirs('logs', exist_ok=True)

# FastAPI应用
app = FastAPI(
    title="MediaGenie Media Processing Service",
    description="AI媒体处理服务，提供语音转写、文本转语音、图像分析等功能",
    version="1.0.0"
)

# 导入 Marketplace 路由
try:
    from marketplace import marketplace_router
    app.include_router(marketplace_router)
    logger.info("Marketplace router registered successfully")
except ImportError as e:
    logger.warning(f"Marketplace router not available: {e}")

# 性能监控装饰�?def monitor_performance(func):
    import functools
    @functools.wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            duration = time.time() - start_time
            logger.info(f"{func.__name__} completed in {duration:.2f}s")
            return result
        except Exception as e:
            duration = time.time() - start_time
            logger.error(f"{func.__name__} failed after {duration:.2f}s: {str(e)}")
            raise
    return wrapper

# 全局异常处理�?from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception on {request.url}: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": "An unexpected error occurred",
            "path": str(request.url)
        }
    )

# 请求日志中间�?@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    logger.info(f"Request: {request.method} {request.url}")
    response = await call_next(request)
    process_time = time.time() - start_time
    logger.info(f"Response: {response.status_code} - {process_time:.2f}s")
    return response

# CORS配置 - 支持本地开发和Azure生产环境
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        # 本地开发环�?        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:3002",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        # Azure Web App域名 - 使用通配符支持所有可能的应用名称
        "https://mediagenie-frontend-prod.azurewebsites.net",
        "https://mediagenie-backend-prod.azurewebsites.net",
        "https://mediagenie-portal-prod.azurewebsites.net",
        # 支持其他可能的命名模�?        "https://mediagenie-fe.azurewebsites.net",
        "https://mediagenie-be.azurewebsites.net",
        "https://mediagenie-mp.azurewebsites.net",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 数据模型
class TextToSpeechRequest(BaseModel):
    text: str
    voice: Optional[str] = "zh-CN-XiaoxiaoNeural"
    format: Optional[str] = "audio-24khz-48kbitrate-mono-mp3"

class SpeechToTextRequest(BaseModel):
    audio_base64: str
    language: Optional[str] = "zh-CN"

class ImageAnalysisRequest(BaseModel):
    image_base64: str
    features: Optional[List[str]] = ["objects", "text", "tags"]

class GPTChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None

class TaskStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class TaskType(str, Enum):
    TEXT_TO_SPEECH = "text_to_speech"
    SPEECH_TO_TEXT = "speech_to_text"
    IMAGE_ANALYSIS = "image_analysis"
    GPT_CHAT = "gpt_chat"

class Task(BaseModel):
    id: str
    userId: Optional[str] = None
    taskType: TaskType
    status: TaskStatus
    priority: int = 1
    inputFileUrl: Optional[str] = None
    inputFileName: Optional[str] = None
    inputFileSize: Optional[int] = None
    outputFileUrl: Optional[str] = None
    outputFileName: Optional[str] = None
    outputFileSize: Optional[int] = None
    parameters: Dict[str, Any]
    result: Optional[Dict[str, Any]] = None
    errorMessage: Optional[str] = None
    processingTime: Optional[float] = None
    createdAt: datetime
    startedAt: Optional[datetime] = None
    completedAt: Optional[datetime] = None
    updatedAt: datetime
    progress: Optional[int] = None

    class Config:
        use_enum_values = True

class Pagination(BaseModel):
    current: int
    pageSize: int
    total: int
    totalPages: int

class TaskListResponse(BaseModel):
    tasks: List[Task]
    pagination: Pagination

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    services: Dict[str, str]


class BasicResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None

# Azure服务配置
class AzureConfig:
    def __init__(self):
        self.speech_key = os.getenv("AZURE_SPEECH_KEY")
        self.speech_region = os.getenv("AZURE_SPEECH_REGION")
        self.vision_key = os.getenv("AZURE_VISION_KEY")
        self.vision_endpoint = os.getenv("AZURE_VISION_ENDPOINT")
        self.storage_connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
        
    def is_speech_configured(self) -> bool:
        return bool(self.speech_key and self.speech_region)
    
    def is_vision_configured(self) -> bool:
        return bool(self.vision_key and self.vision_endpoint)
    
    def is_storage_configured(self) -> bool:
        return bool(self.storage_connection_string)

azure_config = AzureConfig()

# 数据库服�?class DatabaseService:
    def __init__(self):
        self.pool = None
        self.redis_client = None

    async def init_database(self):
        """初始化数据库连接"""
        if not DATABASE_AVAILABLE:
            logger.warning("Database not available, using in-memory storage")
            return

        try:
            # PostgreSQL连接
            database_url = os.getenv("DATABASE_URL")
            if database_url:
                self.pool = await asyncpg.create_pool(database_url)
                logger.info("PostgreSQL connection established")

                # 创建�?                await self.create_tables()

            # Redis连接
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
            self.redis_client = redis.from_url(redis_url)
            await self.redis_client.ping()
            logger.info("Redis connection established")

        except Exception as e:
            logger.error(f"Database initialization failed: {e}")

    async def create_tables(self):
        """创建数据库表"""
        if not self.pool:
            return

        async with self.pool.acquire() as conn:
            # 创建任务�?            await conn.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id VARCHAR(50) PRIMARY KEY,
                    user_id VARCHAR(50),
                    task_type VARCHAR(50) NOT NULL,
                    status VARCHAR(50) NOT NULL,
                    priority INTEGER DEFAULT 1,
                    input_file_url TEXT,
                    input_file_name VARCHAR(255),
                    input_file_size BIGINT,
                    output_file_url TEXT,
                    output_file_name VARCHAR(255),
                    output_file_size BIGINT,
                    parameters JSONB,
                    result JSONB,
                    error_message TEXT,
                    processing_time FLOAT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    started_at TIMESTAMP,
                    completed_at TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    progress INTEGER
                )
            """)

            # 创建索引
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id)")
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)")
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at)")

    async def save_task(self, task: 'Task'):
        """保存任务到数据库"""
        if not self.pool:
            return

        async with self.pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO tasks (
                    id, user_id, task_type, status, priority,
                    input_file_url, input_file_name, input_file_size,
                    output_file_url, output_file_name, output_file_size,
                    parameters, result, error_message, processing_time,
                    created_at, started_at, completed_at, updated_at, progress
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                ON CONFLICT (id) DO UPDATE SET
                    status = EXCLUDED.status,
                    result = EXCLUDED.result,
                    error_message = EXCLUDED.error_message,
                    processing_time = EXCLUDED.processing_time,
                    started_at = EXCLUDED.started_at,
                    completed_at = EXCLUDED.completed_at,
                    updated_at = EXCLUDED.updated_at,
                    progress = EXCLUDED.progress
            """,
                task.id, task.userId, task.taskType.value, task.status.value, task.priority,
                task.inputFileUrl, task.inputFileName, task.inputFileSize,
                task.outputFileUrl, task.outputFileName, task.outputFileSize,
                json.dumps(task.parameters), json.dumps(task.result) if task.result else None,
                task.errorMessage, task.processingTime,
                task.createdAt, task.startedAt, task.completedAt, task.updatedAt, task.progress
            )

    async def get_task(self, task_id: str) -> Optional['Task']:
        """从数据库获取任务"""
        if not self.pool:
            return None

        async with self.pool.acquire() as conn:
            row = await conn.fetchrow("SELECT * FROM tasks WHERE id = $1", task_id)
            if row:
                return self._row_to_task(row)
        return None

    def _row_to_task(self, row) -> 'Task':
        """将数据库行转换为Task对象"""
        return Task(
            id=row['id'],
            userId=row['user_id'],
            taskType=TaskType(row['task_type']),
            status=TaskStatus(row['status']),
            priority=row['priority'],
            inputFileUrl=row['input_file_url'],
            inputFileName=row['input_file_name'],
            inputFileSize=row['input_file_size'],
            outputFileUrl=row['output_file_url'],
            outputFileName=row['output_file_name'],
            outputFileSize=row['output_file_size'],
            parameters=json.loads(row['parameters']) if row['parameters'] else {},
            result=json.loads(row['result']) if row['result'] else None,
            errorMessage=row['error_message'],
            processingTime=row['processing_time'],
            createdAt=row['created_at'],
            startedAt=row['started_at'],
            completedAt=row['completed_at'],
            updatedAt=row['updated_at'],
            progress=row['progress']
        )

# Azure存储服务
class StorageService:
    def __init__(self):
        self.blob_service_client = None
        if AZURE_AVAILABLE and azure_config.is_storage_configured():
            self.blob_service_client = BlobServiceClient.from_connection_string(
                azure_config.storage_connection_string
            )

    async def upload_file(self, container_name: str, blob_name: str, data: bytes) -> str:
        """上传文件到Azure Blob Storage"""
        if not self.blob_service_client:
            raise HTTPException(status_code=503, detail="Storage service not available")

        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=container_name,
                blob=blob_name
            )
            blob_client.upload_blob(data, overwrite=True)
            return blob_client.url
        except Exception as e:
            logger.error(f"File upload failed: {e}")
            raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")

    async def download_file(self, container_name: str, blob_name: str) -> bytes:
        """从Azure Blob Storage下载文件"""
        if not self.blob_service_client:
            raise HTTPException(status_code=503, detail="Storage service not available")

        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=container_name,
                blob=blob_name
            )
            return blob_client.download_blob().readall()
        except Exception as e:
            logger.error(f"File download failed: {e}")
            raise HTTPException(status_code=500, detail=f"File download failed: {str(e)}")

# 初始化服�?database_service = DatabaseService()
storage_service = StorageService()

# 任务管理�?class TaskManager:
    def __init__(self):
        self.tasks: Dict[str, Task] = {}
    
    def create_task(self, task_type: TaskType, input_data: Dict[str, Any]) -> Task:
        task_id = str(uuid.uuid4())
        now = datetime.now()
        task = Task(
            id=task_id,
            userId=input_data.get("userId"),
            taskType=task_type,
            status=TaskStatus.PENDING,
            priority=input_data.get("priority", 1),
            inputFileName=input_data.get("filename"),
            inputFileSize=input_data.get("fileSize"),
            inputFileUrl=input_data.get("fileUrl"),
            parameters=input_data,
            createdAt=now,
            updatedAt=now,
            progress=0
        )
        self.tasks[task_id] = task
        return task
    
    def update_task_status(self, task_id: str, status: TaskStatus, 
                          result: Optional[Dict[str, Any]] = None,
                          error: Optional[str] = None,
                          progress: Optional[int] = None) -> Optional[Task]:
        if task_id not in self.tasks:
            return None
        
        task = self.tasks[task_id]
        now = datetime.now()
        task.status = status
        task.updatedAt = now

        if status == TaskStatus.PROCESSING and task.startedAt is None:
            task.startedAt = now
        if status == TaskStatus.COMPLETED:
            task.completedAt = now
            if task.startedAt:
                task.processingTime = (now - task.startedAt).total_seconds()
        if status == TaskStatus.FAILED and task.startedAt and not task.completedAt:
            task.processingTime = (now - task.startedAt).total_seconds()
        
        if result is not None:
            task.result = result
        if error is not None:
            task.errorMessage = error
        if progress is not None:
            task.progress = progress
            
        return task
    
    def get_task(self, task_id: str) -> Optional[Task]:
        return self.tasks.get(task_id)
    
    def get_tasks(self, page: int = 1, page_size: int = 10, 
                  task_type: Optional[TaskType] = None,
                  status: Optional[TaskStatus] = None) -> TaskListResponse:
        # 过滤任务
        filtered_tasks = list(self.tasks.values())
        
        if task_type:
            filtered_tasks = [t for t in filtered_tasks if t.taskType == task_type]
        if status:
            filtered_tasks = [t for t in filtered_tasks if t.status == status]
        
        # 按创建时间倒序排序
        filtered_tasks.sort(key=lambda x: x.createdAt, reverse=True)
        
        # 分页
        total = len(filtered_tasks)
        start = (page - 1) * page_size
        end = start + page_size
        page_tasks = filtered_tasks[start:end]
        
        total_pages = (total + page_size - 1) // page_size
        
        return TaskListResponse(
            tasks=page_tasks,
            pagination=Pagination(
                current=page,
                pageSize=page_size,
                total=total,
                totalPages=total_pages
            )
        )

task_manager = TaskManager()

def serialize_task(task: Task) -> Dict[str, Any]:
    """将任务对象转换为JSON友好的结�?""
    return jsonable_encoder(task)

# Azure OpenAI聊天功能
async def generate_azure_openai_response(message: str, conversation_id: str) -> tuple[str, bool]:
    """使用Azure OpenAI生成聊天回复，返�?回复内容, 是否使用真实Azure服务)"""
    print(f"🔥🔥 generate_azure_openai_response 被调�?)
    print(f"🔥🔥 message='{message}', conversation_id='{conversation_id}'")

    try:
        # 检查AzureOpenAI模块是否可用
        try:
            from openai import AzureOpenAI
        except ImportError:
            print("🔥🔥 AzureOpenAI模块不可用，使用模拟回复")
            return generate_mock_chat_response(message), False

        # 获取Azure OpenAI配置
        azure_openai_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        azure_openai_key = os.getenv("AZURE_OPENAI_KEY")
        azure_openai_deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-4.1")
        azure_openai_api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2025-01-01-preview")

        print(f"🔥🔥 配置检�? endpoint={azure_openai_endpoint}, key={'SET' if azure_openai_key else 'NOT SET'}, deployment={azure_openai_deployment}, api_version={azure_openai_api_version}")

        if not all([azure_openai_endpoint, azure_openai_key]):
            print("🔥🔥 Azure OpenAI配置不完整，使用模拟回复")
            return generate_mock_chat_response(message), False

        # 根据官方示例创建Azure OpenAI客户�?        print(f"🔥🔥 创建AzureOpenAI客户�?..")

        client = AzureOpenAI(
            azure_endpoint=azure_openai_endpoint,
            api_key=azure_openai_key,
            api_version=azure_openai_api_version
        )

        # 准备聊天提示词（按照官方示例格式�?        chat_prompt = [
            {
                "role": "system",
                "content": [
                    {
                        "type": "text",
                        "text": "你是MediaGenie的智能助手，专门帮助用户使用AI媒体处理服务。MediaGenie提供语音转文字、文本转语音、图像分析、GPT智能对话等功能。请用友好、专业的语调回答用户问题�?
                    }
                ]
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": message
                    }
                ]
            }
        ]

        print(f"🔥🔥 调用Azure OpenAI API...")

        # 生成完成（按照官方示例参数）
        completion = client.chat.completions.create(
            model=azure_openai_deployment,
            messages=chat_prompt,
            max_tokens=1000,
            temperature=0.7,
            top_p=0.95,
            frequency_penalty=0,
            presence_penalty=0,
            stop=None,
            stream=False
        )

        response_content = completion.choices[0].message.content
        print(f"🔥🔥 Azure OpenAI调用成功，响应长�? {len(response_content) if response_content else 0}")
        print(f"🔥🔥 响应内容预览: {response_content[:100] if response_content else 'None'}...")

        return response_content, True

    except Exception as e:
        print(f"🔥🔥 Azure OpenAI调用失败: {e}")
        print(f"🔥🔥 错误类型: {type(e).__name__}")
        import traceback
        print(f"🔥🔥 错误堆栈: {traceback.format_exc()}")
        return generate_mock_chat_response(message), False

# 简单的GPT聊天模拟（降级方案）
def generate_mock_chat_response(message: str) -> str:
    """根据用户消息生成简单的模拟回复"""
    normalized = message.lower()

    keyword_responses = [
        (['price', 'pricing', '订阅', 'plan'], "我们的订阅计划包含基础版、专业版和企业版，可以在账单页面查看详细价格和功能对比�?),
        (['speech', '语音', '转写'], "语音服务支持中文、英文、日文等多种语言，您可以上传音频文件进行实时转写�?),
        (['image', '图像', 'vision'], "图像分析可以识别对象、提取标签并进行OCR文字识别，帮助您快速理解图片内容�?),
        (['help', '使用指南', '教程'], "您可以在帮助中心查看详细的使用指南，也可以告诉我具体问题，我会一步步协助您�?),
        (['error', '故障', '失败'], "请提供具体的错误信息或截图，我可以帮助您排查可能的原因并提供解决建议�?),
    ]

    for keywords, response in keyword_responses:
        if any(keyword in normalized for keyword in keywords):
            return response

    if len(message) < 10:
        return "收到您的消息，可以详细描述一下您的需求或问题吗？"

    return "这是一个模拟回复：我已经理解了您的问题，可以提供更多细节以便进一步帮助您吗？"

# Azure Speech服务
class SpeechService:
    def __init__(self):
        self.speech_config = None
        if not azure_config.is_speech_configured():
            logger.warning("Azure Speech service not configured. Falling back to offline mode.")
            return

        try:
            import azure.cognitiveservices.speech as speechsdk  # type: ignore
            self.speech_config = speechsdk.SpeechConfig(
                subscription=azure_config.speech_key,
                region=azure_config.speech_region
            )
        except ImportError:
            logger.warning("Azure Speech SDK not available. Falling back to offline mode.")
            self.speech_config = None

    def speech_to_text(self, audio_data: bytes, language: str = "zh-CN") -> dict:
        """语音转文�?""
        if not self.speech_config:
            return {"text": "[模拟] 语音转文字功�?, "confidence": 0.0, "language": language}

        try:
            import azure.cognitiveservices.speech as speechsdk
            import tempfile
            import os

            print(f"[STT] 开始语音识�?- 数据大小: {len(audio_data)} bytes, 语言: {language}")

            # 使用临时文件方式 - 更可�?            # 创建临时WAV文件
            with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
                temp_path = temp_file.name
                temp_file.write(audio_data)
                print(f"[STT] 创建临时文件: {temp_path}")

            try:
                # 设置识别语言
                self.speech_config.speech_recognition_language = language

                # 使用文件作为音频输入 - Azure SDK会自动处理WAV�?                audio_config = speechsdk.audio.AudioConfig(filename=temp_path)

                # 创建识别�?                recognizer = speechsdk.SpeechRecognizer(
                    speech_config=self.speech_config,
                    audio_config=audio_config
                )

                print(f"[STT] 开始识�?..")

                # 执行识别
                result = recognizer.recognize_once()
                print(f"[STT] 识别完成 - Reason: {result.reason}")

                if result.reason == speechsdk.ResultReason.RecognizedSpeech:
                    print(f"[STT] �?识别成功: {result.text}")
                    return {
                        "text": result.text,
                        "confidence": 1.0,
                        "language": language
                    }
                elif result.reason == speechsdk.ResultReason.NoMatch:
                    no_match_details = result.no_match_details
                    print(f"[STT] ⚠️  未检测到语音 - Reason: {no_match_details.reason if no_match_details else 'Unknown'}")
                    return {
                        "text": "",
                        "confidence": 0.0,
                        "language": language,
                        "reason": f"No speech detected: {no_match_details.reason if no_match_details else 'Unknown'}"
                    }
                elif result.reason == speechsdk.ResultReason.Canceled:
                    cancellation = result.cancellation_details
                    error_msg = f"识别被取�?- Reason: {cancellation.reason}"
                    if cancellation.reason == speechsdk.CancellationReason.Error:
                        error_msg += f" | Error Code: {cancellation.error_code} | Details: {cancellation.error_details}"
                    print(f"[STT] �?{error_msg}")
                    return {
                        "text": f"[错误] {error_msg}",
                        "confidence": 0.0,
                        "language": language
                    }
                else:
                    error_msg = f"未知的识别结�? {result.reason}"
                    print(f"[STT] �?{error_msg}")
                    return {
                        "text": f"[错误] {error_msg}",
                        "confidence": 0.0,
                        "language": language
                    }
            finally:
                # 清理临时文件
                try:
                    os.unlink(temp_path)
                    print(f"[STT] 清理临时文件: {temp_path}")
                except:
                    pass

        except Exception as e:
            import traceback
            error_detail = traceback.format_exc()
            print(f"[STT] �?异常: {e}")
            print(f"[STT] 详细信息:\n{error_detail}")
            return {"text": f"[错误] 语音识别异常: {str(e)}", "confidence": 0.0, "language": language}

    def text_to_speech(
        self,
        text: str,
        voice: str = "zh-CN-XiaoxiaoNeural",
        format: str = "audio-24khz-48kbitrate-mono-mp3",
    ) -> Tuple[bytes, str, bool]:
        """文本转语�?
        Returns a tuple of (audio_bytes, mime_type, used_fallback)
        """
        desired_mime = "audio/mpeg" if "mp3" in (format or "").lower() else "audio/wav"

        if not self.speech_config:
            fallback_audio = self._generate_fallback_audio(text)
            return fallback_audio, "audio/wav", True

        try:
            import azure.cognitiveservices.speech as speechsdk  # type: ignore

            self.speech_config.speech_synthesis_voice_name = voice
            synthesizer = speechsdk.SpeechSynthesizer(speech_config=self.speech_config)
            result = synthesizer.speak_text_async(text).get()

            if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
                return result.audio_data, desired_mime, False

            if result.reason == speechsdk.ResultReason.Canceled:
                cancellation_details = result.cancellation_details
                error_msg = f"Speech synthesis canceled: {cancellation_details.reason}"
                if cancellation_details.error_details:
                    error_msg += f" - {cancellation_details.error_details}"
            else:
                error_msg = f"Speech synthesis failed: {result.reason}"

            logger.warning("Azure TTS returned non-success result: %s", error_msg)
            fallback_audio = self._generate_fallback_audio(text)
            return fallback_audio, "audio/wav", True

        except Exception as e:  # pylint: disable=broad-except
            logger.warning("Text to speech error: %s", e, exc_info=True)
            fallback_audio = self._generate_fallback_audio(text)
            return fallback_audio, "audio/wav", True

    @staticmethod
    def _generate_fallback_audio(text: str) -> bytes:
        """Generate a simple sine wave WAV audio as a fallback result."""
        duration_seconds = min(5.0, max(1.0, len(text) / 10.0))
        sample_rate = 16000
        amplitude = 16000
        frequency = 440.0

        buffer = io.BytesIO()
        with wave.open(buffer, "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)

            for i in range(int(sample_rate * duration_seconds)):
                sample = int(amplitude * math.sin(2 * math.pi * frequency * (i / sample_rate)))
                wav_file.writeframes(struct.pack("<h", sample))

        buffer.seek(0)
        return buffer.read()

# Azure Vision服务
class VisionService:
    def __init__(self):
        if not azure_config.is_vision_configured():
            logger.warning("Azure Vision service not configured")
            return

        if AZURE_AVAILABLE:
            self.vision_client = ComputerVisionClient(
                azure_config.vision_endpoint,
                CognitiveServicesCredentials(azure_config.vision_key)
            )

    def analyze_image(self, image_data: bytes, features: List[str]) -> Dict[str, Any]:
        """分析图像"""
        if not AZURE_AVAILABLE or not azure_config.is_vision_configured():
            raise HTTPException(status_code=503, detail="Vision service not available")

        try:
            # 创建图像�?            image_stream = io.BytesIO(image_data)

            result = {}

            # 对象检�?            if "objects" in features:
                try:
                    objects_result = self.vision_client.detect_objects_in_stream(image_stream)
                    result["objects"] = [
                        {
                            "name": obj.object_property,
                            "confidence": obj.confidence,
                            "rectangle": {
                                "x": obj.rectangle.x,
                                "y": obj.rectangle.y,
                                "w": obj.rectangle.w,
                                "h": obj.rectangle.h
                            }
                        }
                        for obj in objects_result.objects
                    ]
                    image_stream.seek(0)  # 重置流位�?                except Exception as e:
                    logger.warning(f"Object detection failed: {str(e)}")
                    result["objects"] = []

            # OCR文字识别
            if "text" in features:
                try:
                    ocr_result = self.vision_client.read_in_stream(image_stream, raw=True)
                    operation_id = ocr_result.headers["Operation-Location"].split("/")[-1]

                    # 等待OCR完成
                    import time
                    while True:
                        read_result = self.vision_client.get_read_result(operation_id)
                        if read_result.status not in ['notStarted', 'running']:
                            break
                        time.sleep(1)

                    text_results = []
                    if read_result.status == OperationStatusCodes.succeeded:
                        for text_result in read_result.analyze_result.read_results:
                            for line in text_result.lines:
                                text_results.append({
                                    "text": line.text,
                                    "confidence": line.appearance.style.confidence if line.appearance else 1.0,
                                    "bounding_box": line.bounding_box
                                })

                    result["text"] = {
                        "lines": text_results,
                        "full_text": " ".join([line["text"] for line in text_results])
                    }
                    image_stream.seek(0)  # 重置流位�?                except Exception as e:
                    logger.warning(f"OCR failed: {str(e)}")
                    result["text"] = {"lines": [], "full_text": ""}

            # 标签识别
            if "tags" in features:
                try:
                    tags_result = self.vision_client.tag_image_in_stream(image_stream)
                    result["tags"] = [
                        {
                            "name": tag.name,
                            "confidence": tag.confidence
                        }
                        for tag in tags_result.tags
                    ]
                    image_stream.seek(0)  # 重置流位�?                except Exception as e:
                    logger.warning(f"Tag detection failed: {str(e)}")
                    result["tags"] = []

            # 图像描述
            if "description" in features:
                try:
                    description_result = self.vision_client.describe_image_in_stream(image_stream)
                    result["description"] = {
                        "captions": [
                            {
                                "text": caption.text,
                                "confidence": caption.confidence
                            }
                            for caption in description_result.captions
                        ],
                        "tags": description_result.tags
                    }
                    image_stream.seek(0)  # 重置流位�?                except Exception as e:
                    logger.warning(f"Description failed: {str(e)}")
                    result["description"] = {"captions": [], "tags": []}

            # 分类
            if "categories" in features:
                try:
                    analysis_result = self.vision_client.analyze_image_in_stream(
                        image_stream,
                        visual_features=["Categories"]
                    )
                    result["categories"] = [
                        {
                            "name": category.name,
                            "score": category.score
                        }
                        for category in analysis_result.categories
                    ]
                    image_stream.seek(0)  # 重置流位�?                except Exception as e:
                    logger.warning(f"Category analysis failed: {str(e)}")
                    result["categories"] = []

            if "faces" in features and "faces" not in result:
                # 当前未集成实际的人脸识别，返回空结果占位
                result["faces"] = []

            return result

        except Exception as e:
            logger.error(f"Image analysis error: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Image analysis failed: {str(e)}")

# 初始化服�?speech_service = SpeechService()
vision_service = VisionService()

# 应用启动事件
@app.on_event("startup")
async def startup_event():
    """应用启动时初始化数据库连�?""
    await database_service.init_database()
    logger.info("MediaGenie Media Service started successfully")

@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭时清理资�?""
    if database_service.pool:
        await database_service.pool.close()
    if database_service.redis_client:
        await database_service.redis_client.close()
    logger.info("MediaGenie Media Service shutdown completed")

# API端点
@app.get("/", response_model=Dict[str, str])
async def root():
    """根端�?""
    return {
        "service": "MediaGenie Media Processing Service",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/api/media/tasks", response_model=TaskListResponse)
async def list_media_tasks(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    task_type: Optional[TaskType] = Query(None),
    status: Optional[TaskStatus] = Query(None)
):
    """获取任务列表"""
    return task_manager.get_tasks(
        page=page,
        page_size=page_size,
        task_type=task_type,
        status=status
    )


@app.get("/api/media/tasks/{task_id}", response_model=Dict[str, Any])
async def get_media_task(task_id: str):
    """获取单个任务详情"""
    task = task_manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"task": serialize_task(task)}


@app.delete("/api/media/tasks/{task_id}", response_model=BasicResponse)
async def delete_media_task(task_id: str):
    """删除任务（演示用途，仅从内存移除�?""
    task = task_manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task_manager.tasks.pop(task_id, None)
    return BasicResponse(message="Task deleted")


@app.post("/api/media/tasks/{task_id}/retry", response_model=BasicResponse)
async def retry_media_task(task_id: str):
    """重新执行任务（演示实现，返回提示�?""
    task = task_manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    task_manager.update_task_status(task_id, TaskStatus.PENDING, progress=0)
    return BasicResponse(message="Task marked for retry. Please resubmit input if required.")


@app.get("/api/media/tasks/{task_id}/download")
async def download_media_task_result(task_id: str):
    """下载任务结果（如果有可用输出文件�?""
    task = task_manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    if not task.outputFileUrl and not task.result:
        raise HTTPException(status_code=404, detail="Task has no downloadable output")

    if task.outputFileUrl:
        return JSONResponse({
            "redirect": task.outputFileUrl,
            "message": "Use the provided URL to download the output"
        })

    return JSONResponse({
        "task": serialize_task(task)
    })

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """健康检�?""
    print("🔥🔥🔥 健康检查端点被调用")
    logger.info("健康检查端点被调用")
    services = {
        "speech": "available" if azure_config.is_speech_configured() else "not_configured",
        "vision": "available" if azure_config.is_vision_configured() else "not_configured",
        "storage": "available" if azure_config.is_storage_configured() else "not_configured"
    }

    overall_status = "healthy"
    if any(value != "available" for value in services.values()):
        overall_status = "degraded"

    return HealthResponse(
        status=overall_status,
        timestamp=datetime.utcnow().isoformat(),
        services=services,
    )

@app.post("/api/speech/text-to-speech")
@monitor_performance
async def text_to_speech_endpoint(request: TextToSpeechRequest):
    """文本转语音API"""
    # 创建任务
    task = task_manager.create_task(
        task_type=TaskType.TEXT_TO_SPEECH,
        input_data={
            "text": request.text,
            "voice": request.voice,
            "format": request.format
        }
    )
    
    try:
        # 更新任务状态为处理�?        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=50)
        
        audio_data, media_type, used_fallback = speech_service.text_to_speech(
            text=request.text,
            voice=request.voice or "zh-CN-XiaoxiaoNeural",
            format=request.format or "audio-24khz-48kbitrate-mono-mp3"
        )
        
        # 更新任务状态为完成
        task_manager.update_task_status(
            task.id, 
            TaskStatus.COMPLETED, 
            result={
                "audio_size": len(audio_data),
                "format": media_type,
                "voice": request.voice,
                "requested_format": request.format or "audio-24khz-48kbitrate-mono-mp3",
                "fallback": used_fallback
            },
            progress=100
        )
        
        headers = {
            "Content-Disposition": f"inline; filename=tts_{task.id}.{('mp3' if media_type == 'audio/mpeg' else 'wav')}",
            "X-Task-ID": task.id,
        }
        if used_fallback:
            headers["X-TTS-Fallback"] = "true"

        return StreamingResponse(
            io.BytesIO(audio_data),
            media_type=media_type,
            headers=headers,
        )
    except Exception as e:
        # 更新任务状态为失败
        task_manager.update_task_status(task.id, TaskStatus.FAILED, error=str(e))
        logger.error(f"Text-to-speech error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/speech/speech-to-text")
@monitor_performance
async def speech_to_text_endpoint(request: SpeechToTextRequest):
    """语音转文字API"""
    # 创建任务
    task = task_manager.create_task(
        task_type=TaskType.SPEECH_TO_TEXT,
        input_data={
            "language": request.language or "zh-CN",
            "audio_size": len(request.audio_base64)
        }
    )
    
    try:
        # 更新任务状态为处理�?        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=50)
        
        # 解码base64音频数据
        audio_data = base64.b64decode(request.audio_base64)
        
        stt_raw = speech_service.speech_to_text(
            audio_data=audio_data,
            language=request.language or "zh-CN"
        )

        formatted_result = {
            "transcript": stt_raw.get("text", ""),
            "confidence": stt_raw.get("confidence"),
            "language": stt_raw.get("language", request.language or "zh-CN"),
            "raw": stt_raw,
        }
        
        # 更新任务状态为完成
        task_manager.update_task_status(
            task.id, 
            TaskStatus.COMPLETED, 
            result=formatted_result,
            progress=100
        )

        updated_task = task_manager.get_task(task.id)
        return {"task": serialize_task(updated_task)}
    except Exception as e:
        # 更新任务状态为失败
        task_manager.update_task_status(task.id, TaskStatus.FAILED, error=str(e))
        logger.error(f"Speech-to-text error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/speech/speech-to-text-file")
async def speech_to_text_file_endpoint(
    file: UploadFile = File(...),
    language: str = Form("zh-CN")
):
    """语音文件转文字API"""
    # 创建任务
    task = task_manager.create_task(
        task_type=TaskType.SPEECH_TO_TEXT,
        input_data={
            "filename": file.filename,
            "content_type": file.content_type,
            "language": language
        }
    )
    
    try:
        # 更新任务状态为处理�?        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=50)
        
        # 读取上传的文�?        audio_data = await file.read()
        
        stt_raw = speech_service.speech_to_text(
            audio_data=audio_data,
            language=language
        )

        formatted_result = {
            "transcript": stt_raw.get("text", ""),
            "confidence": stt_raw.get("confidence"),
            "language": stt_raw.get("language", language),
            "raw": stt_raw,
        }
        
        # 更新任务状态为完成
        task_manager.update_task_status(
            task.id, 
            TaskStatus.COMPLETED, 
            result=formatted_result,
            progress=100
        )

        updated_task = task_manager.get_task(task.id)
        return {"task": serialize_task(updated_task)}
    except Exception as e:
        # 更新任务状态为失败
        task_manager.update_task_status(task.id, TaskStatus.FAILED, error=str(e))
        logger.error(f"Speech-to-text file error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/speech/batch-text-to-speech")
async def batch_text_to_speech_endpoint(texts: List[str], voice: str = "zh-CN-XiaoxiaoNeural"):
    """批量文本转语音API"""
    if len(texts) > 10:
        raise HTTPException(status_code=400, detail="Maximum 10 texts allowed per batch")

    # 创建任务
    task = task_manager.create_task(
        task_type=TaskType.TEXT_TO_SPEECH,
        input_data={
            "texts": texts,
            "voice": voice,
            "batch_size": len(texts)
        }
    )

    try:
        # 更新任务状态为处理�?        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=10)

        results = []
        for i, text in enumerate(texts):
            try:
                audio_data, media_type, used_fallback = speech_service.text_to_speech(text=text, voice=voice)
                results.append({
                    "index": i,
                    "text": text,
                    "audio_base64": base64.b64encode(audio_data).decode('utf-8'),
                    "audio_size": len(audio_data),
                    "mime_type": media_type,
                    "fallback": used_fallback,
                    "success": True
                })
            except Exception as e:
                results.append({
                    "index": i,
                    "text": text,
                    "error": str(e),
                    "success": False
                })

            # 更新进度
            progress = 10 + (i + 1) * 80 // len(texts)
            task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=progress)

        # 更新任务状态为完成
        task_manager.update_task_status(
            task.id,
            TaskStatus.COMPLETED,
            result={"results": results, "total": len(texts), "successful": sum(1 for r in results if r["success"])},
            progress=100
        )

        return {
            "task_id": task.id,
            "results": results,
            "total": len(texts),
            "successful": sum(1 for r in results if r["success"])
        }
    except Exception as e:
        # 更新任务状态为失败
        task_manager.update_task_status(task.id, TaskStatus.FAILED, error=str(e))
        logger.error(f"Batch text-to-speech error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/gpt/chat")
@monitor_performance
async def gpt_chat_endpoint(request: GPTChatRequest):
    """GPT聊天接口（模拟或Azure集成�?""
    print(f"🔥🔥🔥 GPT端点被调�? {request.message[:50]}...")
    conversation_id = request.conversation_id or str(uuid.uuid4())

    task = task_manager.create_task(
        task_type=TaskType.GPT_CHAT,
        input_data={
            "message": request.message,
            "conversation_id": conversation_id
        }
    )

    try:
        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=50)

        print(f"🔥 开始处理GPT请求: {request.message[:50]}...")
        logger.info(f"开始处理GPT请求: {request.message[:50]}...")
        # 使用真实的Azure OpenAI服务
        response_text, is_real_azure = await generate_azure_openai_response(request.message, conversation_id)
        print(f"🔥 GPT响应完成，使用真实Azure服务: {is_real_azure}")
        logger.info(f"GPT响应完成，使用真实Azure服务: {is_real_azure}")

        result = {
            "conversation_id": conversation_id,
            "response": response_text,
            "source": "azure_openai" if is_real_azure else "mock"
        }

        task_manager.update_task_status(
            task.id,
            TaskStatus.COMPLETED,
            result=result,
            progress=100
        )

        return {
            "task_id": task.id,
            **result
        }
    except Exception as e:
        task_manager.update_task_status(task.id, TaskStatus.FAILED, error=str(e))
        logger.error(f"GPT chat error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/speech/voices")
async def get_available_voices():
    """获取可用的语音列�?""
    voices = [
        {
            "name": "zh-CN-XiaoxiaoNeural",
            "display_name": "晓晓 (中文女声)",
            "gender": "Female",
            "locale": "zh-CN"
        },
        {
            "name": "zh-CN-YunxiNeural",
            "display_name": "云希 (中文男声)",
            "gender": "Male",
            "locale": "zh-CN"
        },
        {
            "name": "zh-CN-YunyangNeural",
            "display_name": "云扬 (中文男声)",
            "gender": "Male",
            "locale": "zh-CN"
        },
        {
            "name": "en-US-JennyNeural",
            "display_name": "Jenny (English Female)",
            "gender": "Female",
            "locale": "en-US"
        },
        {
            "name": "en-US-GuyNeural",
            "display_name": "Guy (English Male)",
            "gender": "Male",
            "locale": "en-US"
        }
    ]

    return {"voices": voices}

@app.get("/api/speech/languages")
async def get_supported_languages():
    """获取支持的语言列表"""
    return {
        "languages": [
            {
                "code": "zh-CN",
                "name": "中文 (简�?",
                "native_name": "中文"
            },
            {
                "code": "en-US",
                "name": "English (US)",
                "native_name": "English"
            },
            {
                "code": "ja-JP",
                "name": "Japanese",
                "native_name": "日本�?
            },
            {
                "code": "ko-KR",
                "name": "Korean",
                "native_name": "한국�?
            },
            {
                "code": "fr-FR",
                "name": "French",
                "native_name": "Français"
            },
            {
                "code": "de-DE",
                "name": "German",
                "native_name": "Deutsch"
            },
            {
                "code": "es-ES",
                "name": "Spanish",
                "native_name": "Español"
            }
        ]
    }

# 图像分析端点
@app.post("/api/vision/image-analysis")
@monitor_performance
async def image_analysis_endpoint(request: ImageAnalysisRequest):
    """图像分析API"""
    # 创建任务
    task = task_manager.create_task(
        task_type=TaskType.IMAGE_ANALYSIS,
        input_data={
            "features": request.features or ["objects", "text", "tags"],
            "image_size": len(request.image_base64)
        }
    )

    try:
        # 更新任务状态为处理�?        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=30)

        # 解码base64图像数据
        image_data = base64.b64decode(request.image_base64)

        # 更新进度
        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=60)

        # 执行图像分析
        vision_raw = vision_service.analyze_image(
            image_data=image_data,
            features=request.features or ["objects", "text", "tags"]
        )

        formatted_result = {
            "ocr": {
                "text": (vision_raw.get("text") or {}).get("full_text", ""),
                "lines": (vision_raw.get("text") or {}).get("lines", []),
            } if vision_raw.get("text") else None,
            "objects": vision_raw.get("objects", []),
            "faces": vision_raw.get("faces", []),
            "tags": vision_raw.get("tags", []),
            "description": vision_raw.get("description"),
            "categories": vision_raw.get("categories", []),
            "raw": vision_raw,
        }

        # 更新任务状态为完成
        task_manager.update_task_status(
            task.id,
            TaskStatus.COMPLETED,
            result=formatted_result,
            progress=100
        )

        updated_task = task_manager.get_task(task.id)
        return {"task": serialize_task(updated_task)}
    except Exception as e:
        # 更新任务状态为失败
        task_manager.update_task_status(task.id, TaskStatus.FAILED, error=str(e))
        logger.error(f"Image analysis error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/vision/image-analysis-file")
async def image_analysis_file_endpoint(
    file: UploadFile = File(...),
    features: str = Form("objects,text,tags")
):
    """图像文件分析API"""
    # 解析特征列表
    feature_list = [f.strip() for f in features.split(",") if f.strip()]

    # 创建任务
    task = task_manager.create_task(
        task_type=TaskType.IMAGE_ANALYSIS,
        input_data={
            "filename": file.filename,
            "content_type": file.content_type,
            "features": feature_list
        }
    )

    try:
        # 更新任务状态为处理�?        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=30)

        # 读取上传的文�?        image_data = await file.read()

        # 更新进度
        task_manager.update_task_status(task.id, TaskStatus.PROCESSING, progress=60)

        # 执行图像分析
        vision_raw = vision_service.analyze_image(
            image_data=image_data,
            features=feature_list
        )

        formatted_result = {
            "ocr": {
                "text": (vision_raw.get("text") or {}).get("full_text", ""),
                "lines": (vision_raw.get("text") or {}).get("lines", []),
            } if vision_raw.get("text") else None,
            "objects": vision_raw.get("objects", []),
            "faces": vision_raw.get("faces", []),
            "tags": vision_raw.get("tags", []),
            "description": vision_raw.get("description"),
            "categories": vision_raw.get("categories", []),
            "raw": vision_raw,
        }

        # 更新任务状态为完成
        task_manager.update_task_status(
            task.id,
            TaskStatus.COMPLETED,
            result=formatted_result,
            progress=100
        )

        updated_task = task_manager.get_task(task.id)
        task_payload = serialize_task(updated_task)
        task_payload["filename"] = file.filename
        return {"task": task_payload}
    except Exception as e:
        # 更新任务状态为失败
        task_manager.update_task_status(task.id, TaskStatus.FAILED, error=str(e))
        logger.error(f"Image analysis file error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# 计费相关端点（模拟数据，实际应该从用户服务获取）
@app.get("/api/billing/usage/summary")
async def get_usage_summary():
    """获取使用情况摘要（模拟数据）"""
    current_period = datetime.now().strftime("%Y-%m")

    return {
        "speechMinutesUsed": 15.5,
        "speechMinutesLimit": 500.0,
        "ttsCharactersUsed": 123456,
        "ttsCharactersLimit": 500000,
        "imageRequestsUsed": 42,
        "imageRequestsLimit": 1000,
        "apiCallsUsed": 210,
        "apiCallsLimit": 5000,
        "currentPeriod": current_period
    }

# Azure Marketplace Webhook 端点
class MarketplaceWebhookPayload(BaseModel):
    """Azure Marketplace Webhook负载"""
    action: str
    id: str
    planId: Optional[str] = None
    quantity: Optional[int] = None
    subscription: Optional[Dict[str, Any]] = None
    
@app.post("/api/marketplace/webhook")
async def marketplace_webhook(payload: MarketplaceWebhookPayload):
    """
    Azure Marketplace Connection Webhook
    处理订阅生命周期事件
    """
    try:
        logger.info(f"Marketplace webhook received: {payload.dict()}")
        
        action = payload.action
        subscription_id = payload.id
        
        if action == "subscribe":
            # 处理新订�?            response = {
                "status": "success",
                "message": "Subscription activated successfully",
                "subscriptionId": subscription_id,
                "planId": payload.planId,
                "activatedAt": datetime.utcnow().isoformat()
            }
            
        elif action == "unsubscribe":
            # 处理取消订阅
            response = {
                "status": "success", 
                "message": "Subscription cancelled successfully",
                "subscriptionId": subscription_id,
                "cancelledAt": datetime.utcnow().isoformat()
            }
            
        elif action == "changePlan":
            # 处理计划变更
            response = {
                "status": "success",
                "message": "Plan changed successfully",
                "subscriptionId": subscription_id,
                "newPlanId": payload.planId,
                "changedAt": datetime.utcnow().isoformat()
            }
            
        elif action == "changeQuantity":
            # 处理数量变更
            response = {
                "status": "success",
                "message": "Quantity changed successfully", 
                "subscriptionId": subscription_id,
                "newQuantity": payload.quantity,
                "changedAt": datetime.utcnow().isoformat()
            }
            
        else:
            # 未知操作
            response = {
                "status": "success",
                "message": f"Webhook received for action: {action}",
                "subscriptionId": subscription_id,
                "action": action,
                "processedAt": datetime.utcnow().isoformat()
            }
        
        # 这里可以添加实际的业务逻辑，如�?        # - 更新数据库中的订阅状�?        # - 发送通知邮件
        # - 调用其他服务API
        # - 记录审计日志�?        
        return JSONResponse(content=response, status_code=200)
        
    except Exception as e:
        logger.error(f"Marketplace webhook error: {str(e)}")
        return JSONResponse(
            content={
                "status": "error",
                "message": f"Webhook processing failed: {str(e)}",
                "timestamp": datetime.utcnow().isoformat()
            }, 
            status_code=500
        )

@app.get("/api/marketplace/status")
async def marketplace_status():
    """Marketplace集成状态检�?""
    return {
        "status": "active",
        "service": "MediaGenie",
        "version": "1.0.0",
        "marketplace": {
            "webhook_endpoint": "/api/marketplace/webhook",
            "supported_actions": ["subscribe", "unsubscribe", "changePlan", "changeQuantity"]
        },
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    # 读取环境变量 PORT �?WEBSITES_PORT (Azure App Service)
    port = int(os.getenv("WEBSITES_PORT", os.getenv("PORT", "8001")))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=False,  # 生产环境关闭reload
        log_level="info"
    )
