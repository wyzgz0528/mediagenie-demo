const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 8080;

console.log('🚀 MediaGenie Frontend Server Starting...');
console.log('📁 Serving from:', __dirname);
console.log('🌐 Port:', PORT);

// 健康检查端点
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'mediagenie-frontend',
    timestamp: new Date().toISOString(),
    port: PORT,
    environment: process.env.NODE_ENV || 'production'
  });
});

// 静态文件服务 - 优先服务构建后的文件
const buildPath = path.join(__dirname, 'build');
console.log('📂 Build path:', buildPath);

// 检查build目录是否存在
const fs = require('fs');
if (fs.existsSync(buildPath)) {
  console.log('✅ Build directory found');
  app.use(express.static(buildPath));
} else {
  console.log('⚠️ Build directory not found, serving from root');
  app.use(express.static(__dirname));
}

// SPA路由支持 - 所有路由返回index.html
app.get('*', (req, res) => {
  const indexPath = fs.existsSync(buildPath)
    ? path.join(buildPath, 'index.html')
    : path.join(__dirname, 'index.html');

  console.log('📄 Serving index.html from:', indexPath);

  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('Index.html not found. Please ensure the app is built correctly.');
  }
});

app.listen(PORT, () => {
  console.log('✅ MediaGenie Frontend Server running on port ' + PORT);
  console.log('🔗 Access URL: http://localhost:' + PORT);
});
