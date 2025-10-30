FROM python:3.11-slim

WORKDIR /app

# 复制requirements文件并安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用程序代码
COPY . .

# 创建必要的目录
RUN mkdir -p templates static logs

# 设置环境变量
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1

# 暴露端口
EXPOSE 5000

# 启动应用
CMD ["python", "app.py"]