"""TDD 1일차 샘플: health endpoint smoke."""
from fastapi.testclient import TestClient


def test_health_returns_ok(client: TestClient) -> None:
    res = client.get("{{health_endpoint}}")
    assert res.status_code == 200
    body = res.json()
    assert body["status"] == "ok"


def test_liveness(client: TestClient) -> None:
    res = client.get("{{health_endpoint}}/live")
    assert res.status_code == 200
    assert res.json()["status"] == "live"


def test_readiness(client: TestClient) -> None:
    res = client.get("{{health_endpoint}}/ready")
    assert res.status_code == 200
    assert res.json()["status"] == "ready"
