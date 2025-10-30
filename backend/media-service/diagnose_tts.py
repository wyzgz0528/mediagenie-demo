from fastapi.testclient import TestClient
import main

client = TestClient(main.app)
response = client.post(
    "/api/speech/text-to-speech",
    json={"text": "测试语音合成", "voice": "zh-CN-XiaoxiaoNeural"}
)
print("Status:", response.status_code)
print("Content-Type:", response.headers.get("content-type"))
print("Content-Length:", response.headers.get("content-length"))
print("First bytes:", response.content[:50])
