from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>MediaGenie Marketplace</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .container {
                background: white;
                color: #333;
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            }
            h1 { color: #667eea; }
            .status { 
                background: #e8f5e9; 
                color: #2e7d32; 
                padding: 15px; 
                border-radius: 5px;
                margin: 20px 0;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>ðŸŽ¬ MediaGenie Marketplace</h1>
            <div class="status">
                âœ?Landing Page is running successfully!
            </div>
            <p><strong>Version:</strong> 1.0.0</p>
            <p><strong>Status:</strong> Online</p>
            <p><strong>Deployment:</strong> Azure App Service</p>
            <hr>
            <p>This is the MediaGenie Marketplace Landing Page for Azure Marketplace integration.</p>
            <p><a href="/api/marketplace/webhook">Webhook Endpoint (Backend)</a></p>
        </div>
    </body>
    </html>
    '''

@app.route('/health')
def health():
    return {'status': 'healthy', 'service': 'marketplace-portal'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
