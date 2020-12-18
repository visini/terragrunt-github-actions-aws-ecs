from main import app, API_ROOT
from fastapi.testclient import TestClient


client = TestClient(app)


def test_main():
    response = client.get(API_ROOT + "/")
    assert response.status_code == 200
    assert "status" in response.json()
    assert response.json()["status"] == "up"
