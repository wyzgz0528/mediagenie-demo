# 智网同盛 MediaGenie

## 项目简�?

MediaGenie是一个基于Azure认知服务的智能媒体处理平台，提供语音转文本、文本转语音、图像分析和GPT聊天等功能�?

## 技术架�?

### 前端
- React 18 + TypeScript
- Ant Design UI框架
- 响应式设计，支持移动�?

### 后端
- Python 3.11 + FastAPI
- Azure认知服务集成
- RESTful API设计

### 部署架构
- Azure Web App for Containers
- Azure Container Registry
- Azure Blob Storage (静态网�?
- ARM模板自动化部�?

## 功能特�?

1. **语音转文�?* - 支持多种语言的语音识�?
2. **文本转语�?* - 高质量语音合�?
3. **图像分析** - AI驱动的图像理�?
4. **GPT聊天** - 智能对话助手
5. **历史记录** - 操作历史管理
6. **用户管理** - 完整的认证系�?

## 部署说明

### 本地开�?
`ash
# 后端
cd backend/media-service
pip install -r requirements.txt
python main.py

# 前端
cd frontend
npm install
npm start
`

### Azure Marketplace部署
`powershell
cd azure-deploy
.\deploy_to_marketplace.ps1 -ResourceGroupName "your-rg" -Location "East Asia"
`

### Marketplace Portal Web App �Զ��������
`powershell
cd F:\project\MediaGenie1001
\.\deploy_marketplace_portal.ps1 -ResourceGroup "MediaGenie-RG" -WebAppName "mediagenie-marketplace"
`

�ű����Զ�Ϊ `marketplace-portal` ׼�� `.python_packages` Ŀ¼��д�� `requirements.txt` �г��������������� Zip �������� Azure CLI ���� Zip Deploy����ֻ���������𣬿�׷�� `-SkipDeploy` �����������ɵ�ѹ������

## 环境配置

### 必需的Azure服务
- Azure认知服务 (语音、视觉、OpenAI)
- Azure容器注册�?
- Azure Web应用
- Azure Blob存储

### 环境变量
参考各服务目录下的.env.example文件配置相应的环境变量�?

## 技术支�?

- 公司: 智网同盛
- 邮箱: contact@smartwebco.com
- 网站: https://smartwebco.com
- 技术支�? support@smartwebco.com

## 许可�?

版权所�?© 2024 智网同盛。保留所有权利�?
