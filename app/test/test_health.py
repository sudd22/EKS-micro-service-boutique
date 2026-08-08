from app.services.auth.main import app as auth_app
from app.services.notification.main import app as notification_app
from app.services.order.main import app as order_app
from app.services.payment.main import app as payment_app
from app.services.product.main import app as product_app
from fastapi.testclient import TestClient


def test_auth_health():
    client = TestClient(auth_app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_product_health():
    client = TestClient(product_app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_order_health():
    client = TestClient(order_app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_payment_health():
    client = TestClient(payment_app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_notification_health():
    client = TestClient(notification_app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
