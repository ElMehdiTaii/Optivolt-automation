from fastapi.testclient import TestClient
from app.app import app

client = TestClient(app)


def test_get_heavy_negative_size():
    response = client.get("/simulate/heavy?size_kb=-10")
    assert response.status_code == 200 or response.status_code == 422


def test_get_delay_invalid_type():
    response = client.get("/simulate/delay?ms=hello")
    assert response.status_code == 422


def test_post_normal_empty_payload():
    response = client.post("/simulate/normal", json={})
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["received_preview"] == ""


def test_post_delay_empty_body():
    response = client.post("/simulate/delay?ms=300", json={})
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["delay_ms"] == 300
    assert json_data["received_preview"] == ""
