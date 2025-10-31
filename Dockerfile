# ---------- 构建前端 ----------
FROM node:20 AS frontend-build
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# ---------- 构建后端 ----------
FROM python:3.11-slim AS backend-build
WORKDIR /app
COPY backend/media-service/ ./backend/media-service/
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# ---------- 生产镜像 ----------
FROM python:3.11-slim
WORKDIR /app

COPY --from=backend-build /app/backend/media-service ./backend/media-service
COPY --from=backend-build /app/requirements.txt ./
COPY --from=frontend-build /app/frontend/build ./static

# 关键：最终镜像再装一次依赖，确保 gunicorn/uvicorn 可执行文件在 PATH
RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONUNBUFFERED=1

CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "backend.media-service.main:app", "--bind", "0.0.0.0:8080"]
