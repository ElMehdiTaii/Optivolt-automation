from starlette.testclient import TestClient
from app.app import app

client = TestClient(app)


def test_get_simulate_normal():
    response = client.get("/simulate/normal")
    assert response.status_code == 200
    json_data = response.json()
    assert "response" in json_data
    assert json_data["response"]["message"] == "This is a normal GET response."


def test_get_simulate_heavy_default():
    response = client.get("/simulate/heavy")
    assert response.status_code == 200
    json_data = response.json()
    assert "response" in json_data
    assert "payload" in json_data["response"]
    assert isinstance(json_data["response"]["payload"], str)


def test_get_simulate_heavy_custom_size():
    response = client.get("/simulate/heavy?size_kb=100")
    assert response.status_code == 200
    json_data = response.json()
    assert "payload" in json_data["response"]
    assert isinstance(json_data["response"]["payload"], str)


def test_post_simulate_normal():
    payload = {"content": "Hello world"}
    response = client.post("/simulate/normal", json=payload)
    assert response.status_code == 200
    json_data = response.json()
    assert "received_preview" in json_data
    assert json_data["received_preview"].startswith("Hello")


def test_post_simulate_heavy_generated():
    response = client.post("/simulate/heavy")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["generated"] is True
    assert "received_size_bytes" in json_data


def test_post_simulate_heavy_with_content():
    payload = {"content": "Manual test payload"}
    response = client.post("/simulate/heavy", json=payload)
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["generated"] is False
    assert "received_size_bytes" in json_data


def test_get_simulate_delay_default():
    response = client.get("/simulate/delay")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["delay_ms"] == 500
    assert "response" in json_data


def test_get_simulate_delay_custom():
    response = client.get("/simulate/delay?ms=250")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["delay_ms"] == 250
    assert "response" in json_data


def test_post_simulate_delay_default():
    payload = {"content": "testing delay"}
    response = client.post("/simulate/delay", json=payload)
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["delay_ms"] == 500
    assert json_data["received_preview"].startswith("testing")


def test_post_simulate_delay_custom():
    payload = {"content": "custom delay test"}
    response = client.post("/simulate/delay?ms=150", json=payload)
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["delay_ms"] == 150
    assert json_data["received_preview"].startswith("custom")
