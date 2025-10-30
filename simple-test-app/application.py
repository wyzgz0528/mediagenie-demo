from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>MediaGenie Marketplace Portal</h1><p>Deployment Successful!</p><p>Landing Page URL: <a href="https://mediagenie-marketplace.azurewebsites.net">https://mediagenie-marketplace.azurewebsites.net</a></p>'

@app.route('/health')
def health():
    return {'status': 'healthy', 'service': 'marketplace-portal'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
