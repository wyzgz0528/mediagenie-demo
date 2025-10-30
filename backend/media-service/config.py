"""
配置管理模块

使用 Pydantic Settings 管理环境变量配置
"""

from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field, ConfigDict


class Settings(BaseSettings):
    """应用配置"""
    
    # ============================================
    # 基础配置
    # ============================================
    APP_NAME: str = "MediaGenie"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = "production"  # development / staging / production
    DEBUG: bool = False
    LOG_LEVEL: str = "INFO"
    
    # ============================================
    # Azure AD 认证配置
    # ============================================
    AZURE_AD_TENANT_ID: str = Field(..., description="Azure AD Tenant ID")
    AZURE_AD_CLIENT_ID: str = Field(..., description="Azure AD Application (client) ID")
    AZURE_AD_CLIENT_SECRET: str = Field(..., description="Azure AD Client Secret")
    AZURE_AD_AUTHORITY: Optional[str] = None  # 自动构建
    
    # ============================================
    # Azure Marketplace SaaS API 配置
    # ============================================
    MARKETPLACE_API_BASE_URL: str = "https://marketplaceapi.microsoft.com/api"
    MARKETPLACE_API_VERSION: str = "2018-08-31"
    
    # ============================================
    # 数据库配�?
    # ============================================
    DATABASE_URL: str = Field(
        ...,
        description="PostgreSQL connection string (asyncpg format)"
    )
    REDIS_URL: str = Field(
        default="redis://localhost:6379/0",
        description="Redis connection string"
    )
    
    # 数据库连接池
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_POOL_TIMEOUT: int = 30
    DB_POOL_RECYCLE: int = 3600
    
    # ============================================
    # Azure Cognitive Services 配置
    # ============================================
    AZURE_OPENAI_ENDPOINT: str = Field(..., description="Azure OpenAI endpoint")
    AZURE_OPENAI_KEY: str = Field(..., description="Azure OpenAI key")
    AZURE_OPENAI_DEPLOYMENT: str = Field(
        default="gpt-4",
        description="Azure OpenAI deployment name"
    )
    AZURE_OPENAI_API_VERSION: str = "2024-02-01"
    
    AZURE_SPEECH_KEY: str = Field(..., description="Azure Speech Service key")
    AZURE_SPEECH_REGION: str = Field(
        default="eastus",
        description="Azure Speech Service region"
    )
    
    AZURE_VISION_ENDPOINT: str = Field(..., description="Azure Computer Vision endpoint")
    AZURE_VISION_KEY: str = Field(..., description="Azure Computer Vision key")
    
    AZURE_STORAGE_CONNECTION_STRING: Optional[str] = None
    AZURE_STORAGE_ACCOUNT_NAME: Optional[str] = None
    AZURE_STORAGE_ACCOUNT_KEY: Optional[str] = None
    
    # ============================================
    # CORS 配置
    # ============================================
    FRONTEND_URL: str = Field(
        default="https://mediagenie-frontend.azurewebsites.net",
        description="Frontend application URL"
    )
    MARKETPLACE_PORTAL_URL: str = Field(
        default="https://mediagenie-marketplace-portal.azurewebsites.net",
        description="Marketplace portal URL"
    )
    
    CORS_ORIGINS: list[str] = Field(
        default_factory=lambda: [
            "https://mediagenie-frontend.azurewebsites.net",
            "https://mediagenie-marketplace-portal.azurewebsites.net",
            "http://localhost:3000",  # 开发环�?
        ]
    )
    CORS_ALLOW_CREDENTIALS: bool = True
    CORS_ALLOW_METHODS: list[str] = Field(default_factory=lambda: ["*"])
    CORS_ALLOW_HEADERS: list[str] = Field(default_factory=lambda: ["*"])
    
    # ============================================
    # API 限流配置
    # ============================================
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_PER_HOUR: int = 1000
    
    # ============================================
    # 任务处理配置
    # ============================================
    MAX_FILE_SIZE_MB: int = 100
    TASK_TIMEOUT_SECONDS: int = 600
    CLEANUP_COMPLETED_TASKS_DAYS: int = 30
    
    # ============================================
    # 安全配置
    # ============================================
    SECRET_KEY: str = Field(
        default="change-me-in-production",
        description="Secret key for signing tokens"
    )
    JWT_ALGORITHM: str = "RS256"
    JWT_EXPIRATION_MINUTES: int = 60
    
    # Webhook 签名验证
    WEBHOOK_SIGNATURE_ENABLED: bool = True
    
    # ============================================
    # 监控和日志配�?
    # ============================================
    ENABLE_METRICS: bool = True
    ENABLE_TRACING: bool = True
    
    # Application Insights
    APPLICATIONINSIGHTS_CONNECTION_STRING: Optional[str] = None
    
    # ============================================
    # 特性开�?
    # ============================================
    FEATURE_METERING_ENABLED: bool = False  # 计量计费功能
    FEATURE_AUDIT_LOG_ENABLED: bool = True
    FEATURE_NOTIFICATION_ENABLED: bool = True
    
    # ============================================
    # 属性方�?
    # ============================================
    
    @property
    def azure_ad_authority_url(self) -> str:
        """Azure AD Authority URL"""
        return self.AZURE_AD_AUTHORITY or f"https://login.microsoftonline.com/{self.AZURE_AD_TENANT_ID}"
    
    @property
    def is_development(self) -> bool:
        """是否为开发环�?""
        return self.ENVIRONMENT == "development"
    
    @property
    def is_production(self) -> bool:
        """是否为生产环�?""
        return self.ENVIRONMENT == "production"

    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"  # 忽略 .env 中的额外字段
    )


# 全局配置实例
settings = Settings()


# ============================================
# 日志配置
# ============================================

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
        "detailed": {
            "format": (
                "%(asctime)s - %(name)s - %(levelname)s - "
                "[%(filename)s:%(lineno)d] - %(message)s"
            ),
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": settings.LOG_LEVEL,
            "formatter": "default",
            "stream": "ext://sys.stdout",
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": settings.LOG_LEVEL,
            "formatter": "detailed",
            "filename": "logs/media-service.log",
            "maxBytes": 10485760,  # 10MB
            "backupCount": 5,
        },
    },
    "loggers": {
        "": {  # Root logger
            "level": settings.LOG_LEVEL,
            "handlers": ["console", "file"],
        },
        "uvicorn": {
            "level": "INFO",
            "handlers": ["console"],
            "propagate": False,
        },
        "sqlalchemy": {
            "level": "WARNING",
            "handlers": ["console"],
            "propagate": False,
        },
    },
}
