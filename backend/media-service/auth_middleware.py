"""
Azure AD JWT 认证中间�?

功能:
1. 验证 Azure AD 签发�?JWT token
2. �?JWKS 端点获取公钥
3. 提取用户身份信息 (oid, email, name)
4. 实现 FastAPI Dependency 注入
"""

import logging
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from functools import lru_cache

import jwt
from jwt import PyJWKClient
from jwt.exceptions import (
    ExpiredSignatureError,
    InvalidTokenError,
    InvalidAudienceError,
    InvalidIssuerError
)
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import httpx

# 配置
from config import settings

logger = logging.getLogger(__name__)

# HTTP Bearer Token 提取�?
security = HTTPBearer()


class UserInfo(BaseModel):
    """用户身份信息"""
    oid: str  # Azure AD Object ID (唯一标识)
    sub: str  # Subject (备用标识)
    email: str
    name: Optional[str] = None
    tenant_id: str
    roles: list[str] = []
    
    class Config:
        frozen = True  # 不可�?


class AzureADTokenValidator:
    """Azure AD Token 验证�?""
    
    def __init__(
        self,
        tenant_id: str,
        client_id: str,
        validate_audience: bool = True
    ):
        """
        初始化验证器
        
        Args:
            tenant_id: Azure AD Tenant ID
            client_id: Application (client) ID
            validate_audience: 是否验证 audience (默认 True)
        """
        self.tenant_id = tenant_id
        self.client_id = client_id
        self.validate_audience = validate_audience
        
        # JWKS (公钥�? 端点
        self.jwks_uri = (
            f"https://login.microsoftonline.com/{tenant_id}/discovery/v2.0/keys"
        )
        
        # Issuer (签发�?
        self.issuer = f"https://login.microsoftonline.com/{tenant_id}/v2.0"
        
        # 初始�?JWKS 客户�?(自动获取和缓存公�?
        self.jwks_client = PyJWKClient(
            self.jwks_uri,
            cache_keys=True,
            max_cached_keys=10,
            cache_jwk_set=True,
            lifespan=3600  # 缓存 1 小时
        )
        
        logger.info(
            f"Azure AD Token Validator initialized for tenant {tenant_id}"
        )
    
    def verify_token(self, token: str) -> Dict[str, Any]:
        """
        验证 JWT token 并返�?payload
        
        Args:
            token: JWT token 字符�?
            
        Returns:
            Dict[str, Any]: Token payload (claims)
            
        Raises:
            HTTPException: Token 验证失败
        """
        try:
            # 1. 获取 token header (不验证签�?
            unverified_header = jwt.get_unverified_header(token)
            
            # 2. 根据 kid (key ID) 获取对应的公�?
            signing_key = self.jwks_client.get_signing_key_from_jwt(token)
            
            # 3. 验证 token
            decode_options = {
                "verify_signature": True,
                "verify_exp": True,  # 验证过期时间
                "verify_nbf": True,  # 验证生效时间
                "verify_iat": True,  # 验证签发时间
                "verify_aud": self.validate_audience,  # 验证 audience
                "verify_iss": True,  # 验证 issuer
            }
            
            # 构建 audience 列表 (支持多种格式)
            audiences = [
                self.client_id,  # Client ID
                f"api://{self.client_id}",  # API 格式
            ]
            
            payload = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256"],
                audience=audiences if self.validate_audience else None,
                issuer=self.issuer,
                options=decode_options
            )
            
            logger.debug(f"Token verified for user: {payload.get('oid')}")
            return payload
            
        except ExpiredSignatureError:
            logger.warning("Token has expired")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        except InvalidAudienceError:
            logger.warning(f"Invalid audience in token")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token audience",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        except InvalidIssuerError:
            logger.warning(f"Invalid issuer in token")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token issuer",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        except InvalidTokenError as e:
            logger.error(f"Invalid token: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid token: {str(e)}",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        except Exception as e:
            logger.error(f"Token verification error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token verification failed",
                headers={"WWW-Authenticate": "Bearer"},
            )
    
    def extract_user_info(self, payload: Dict[str, Any]) -> UserInfo:
        """
        �?token payload 提取用户信息
        
        Args:
            payload: JWT payload (claims)
            
        Returns:
            UserInfo: 用户身份信息
        """
        # 提取必需字段
        oid = payload.get("oid")
        if not oid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing 'oid' claim"
            )
        
        sub = payload.get("sub", oid)
        tenant_id = payload.get("tid")
        
        if not tenant_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing 'tid' claim"
            )
        
        # 提取 email (可能在不同字�?
        email = (
            payload.get("email") or 
            payload.get("preferred_username") or 
            payload.get("upn") or
            f"{oid}@unknown.com"  # 后备方案
        )
        
        # 提取可选字�?
        name = payload.get("name")
        roles = payload.get("roles", [])
        
        return UserInfo(
            oid=oid,
            sub=sub,
            email=email,
            name=name,
            tenant_id=tenant_id,
            roles=roles
        )


# 全局验证器实�?(单例)
@lru_cache()
def get_token_validator() -> AzureADTokenValidator:
    """获取 Token 验证器单�?""
    return AzureADTokenValidator(
        tenant_id=settings.AZURE_AD_TENANT_ID,
        client_id=settings.AZURE_AD_CLIENT_ID,
        validate_audience=True
    )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    validator: AzureADTokenValidator = Depends(get_token_validator)
) -> UserInfo:
    """
    FastAPI Dependency: 获取当前登录用户
    
    用法:
        @app.get("/api/protected")
        async def protected_endpoint(user: UserInfo = Depends(get_current_user)):
            return {"message": f"Hello {user.name}"}
    
    Args:
        credentials: HTTP Bearer token
        validator: Token 验证�?
        
    Returns:
        UserInfo: 当前用户信息
        
    Raises:
        HTTPException: 401 如果 token 无效
    """
    token = credentials.credentials
    
    # 验证 token 并提�?payload
    payload = validator.verify_token(token)
    
    # 提取用户信息
    user_info = validator.extract_user_info(payload)
    
    return user_info


async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        HTTPBearer(auto_error=False)
    ),
    validator: AzureADTokenValidator = Depends(get_token_validator)
) -> Optional[UserInfo]:
    """
    FastAPI Dependency: 获取当前登录用户 (可�?
    
    如果未提�?token �?token 无效,返回 None 而不是抛出异�?
    适用于需要支持匿名访问的端点
    
    Args:
        credentials: HTTP Bearer token (可�?
        validator: Token 验证�?
        
    Returns:
        Optional[UserInfo]: 当前用户信息,如果未登录则�?None
    """
    if not credentials:
        return None
    
    try:
        token = credentials.credentials
        payload = validator.verify_token(token)
        user_info = validator.extract_user_info(payload)
        return user_info
    except HTTPException:
        return None


async def require_roles(required_roles: list[str]):
    """
    FastAPI Dependency: 要求用户具有特定角色
    
    用法:
        @app.get("/api/admin")
        async def admin_endpoint(
            user: UserInfo = Depends(get_current_user),
            _: None = Depends(require_roles(["Admin"]))
        ):
            return {"message": "Admin only"}
    
    Args:
        required_roles: 需要的角色列表
        
    Raises:
        HTTPException: 403 如果用户角色不足
    """
    async def check_roles(user: UserInfo = Depends(get_current_user)):
        user_roles = set(user.roles)
        required = set(required_roles)
        
        if not required.intersection(user_roles):
            logger.warning(
                f"User {user.oid} lacks required roles. "
                f"Has: {user_roles}, Required: {required}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires one of roles: {', '.join(required_roles)}"
            )
    
    return check_roles


# ============================================
# Service Principal Token 获取 (用于调用 SaaS API)
# ============================================

class AzureADServicePrincipal:
    """Azure AD Service Principal 认证 (用于服务间调�?"""
    
    def __init__(
        self,
        tenant_id: str,
        client_id: str,
        client_secret: str,
        scope: str = "https://marketplaceapi.microsoft.com/.default"
    ):
        """
        初始�?Service Principal
        
        Args:
            tenant_id: Azure AD Tenant ID
            client_id: Application (client) ID
            client_secret: Client Secret
            scope: 请求的权限范�?
        """
        self.tenant_id = tenant_id
        self.client_id = client_id
        self.client_secret = client_secret
        self.scope = scope
        
        # Token 端点
        self.token_url = (
            f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
        )
        
        # Token 缓存
        self._cached_token: Optional[str] = None
        self._token_expires_at: Optional[datetime] = None
    
    async def get_access_token(self) -> str:
        """
        获取 Access Token (自动缓存和刷�?
        
        Returns:
            str: Access token
            
        Raises:
            HTTPException: 获取 token 失败
        """
        # 检查缓存是否有�?
        if self._cached_token and self._token_expires_at:
            if datetime.now() < self._token_expires_at - timedelta(minutes=5):
                logger.debug("Using cached access token")
                return self._cached_token
        
        # 请求�?token
        logger.info("Requesting new access token from Azure AD")
        
        data = {
            "grant_type": "client_credentials",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "scope": self.scope
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self.token_url,
                    data=data,
                    timeout=30.0
                )
                response.raise_for_status()
                
                result = response.json()
                
                # 缓存 token
                self._cached_token = result["access_token"]
                expires_in = result.get("expires_in", 3600)  # 默认 1 小时
                self._token_expires_at = datetime.now() + timedelta(seconds=expires_in)
                
                logger.info(f"Access token obtained, expires in {expires_in}s")
                return self._cached_token
        
        except httpx.HTTPStatusError as e:
            logger.error(f"Failed to get access token: {e.response.text}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to authenticate with Azure AD"
            )
        
        except Exception as e:
            logger.error(f"Error getting access token: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Authentication service unavailable"
            )


# 全局 Service Principal 实例
@lru_cache()
def get_service_principal() -> AzureADServicePrincipal:
    """获取 Service Principal 单例 (用于调用 Marketplace API)"""
    return AzureADServicePrincipal(
        tenant_id=settings.AZURE_AD_TENANT_ID,
        client_id=settings.AZURE_AD_CLIENT_ID,
        client_secret=settings.AZURE_AD_CLIENT_SECRET,
        scope="https://marketplaceapi.microsoft.com/.default"
    )


# ============================================
# 使用示例
# ============================================

"""
# �?main.py 中使�?

from fastapi import FastAPI, Depends
from auth_middleware import get_current_user, UserInfo, require_roles

app = FastAPI()

# 1. 需要认证的端点
@app.get("/api/profile")
async def get_profile(user: UserInfo = Depends(get_current_user)):
    return {
        "oid": user.oid,
        "email": user.email,
        "name": user.name,
        "tenant_id": user.tenant_id
    }

# 2. 可选认证的端点
@app.get("/api/public")
async def public_endpoint(user: Optional[UserInfo] = Depends(get_current_user_optional)):
    if user:
        return {"message": f"Hello {user.name}"}
    else:
        return {"message": "Hello anonymous user"}

# 3. 需要特定角色的端点
@app.get("/api/admin/users")
async def list_users(
    user: UserInfo = Depends(get_current_user),
    _: None = Depends(require_roles(["Admin"]))
):
    return {"users": []}

# 4. 获取 Service Principal token (用于调用 SaaS API)
from auth_middleware import get_service_principal

service_principal = get_service_principal()
access_token = await service_principal.get_access_token()

# 使用 token 调用 Marketplace API
headers = {"Authorization": f"Bearer {access_token}"}
"""
