"""Test fixtures shared across the suite."""
from __future__ import annotations

import os
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient


os.environ.setdefault("ENVIRONMENT", "test")


@pytest.fixture(scope="session")
def app():
    from {{app_module}}.main import create_app

    return create_app()


@pytest.fixture
def client(app) -> Iterator[TestClient]:
    with TestClient(app) as c:
        yield c
