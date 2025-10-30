# 澶氶樁娈垫瀯寤轰紭鍖?
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# 鐢熶骇闃舵
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 闈瀝oot鐢ㄦ埛杩愯
RUN addgroup -g 1001 -S nginx && \
    adduser -S nginx -u 1001
USER nginx

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
