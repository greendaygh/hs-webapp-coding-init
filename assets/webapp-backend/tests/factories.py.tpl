"""Test factories using factory_boy + faker.

도메인 엔티티/값 객체에 대한 팩토리를 정의한다. 사용자 추가 시 패턴:

    import factory
    from {{app_module}}.domain.user import User

    class UserFactory(factory.Factory):
        class Meta:
            model = User

        id = factory.Sequence(lambda n: f"u{n}")
        email = factory.Faker("email")
        name = factory.Faker("name")

테스트에서:

    def test_user_signup(client):
        user = UserFactory.build()
        ...

faker locale 일괄 변경:

    factory.Faker._DEFAULT_LOCALE = "ko_KR"
"""
from __future__ import annotations

import factory  # type: ignore[import-not-found]
from faker import Faker  # type: ignore[import-not-found]

from {{app_module}}.domain.user import User

fake = Faker()


class _ExampleFactory(factory.Factory):
    """샘플 팩토리 — 실제 도메인 모델로 교체할 것."""

    class Meta:
        model = dict

    id = factory.Sequence(lambda n: f"id-{n}")
    name = factory.Faker("name")
    email = factory.Faker("email")


class UserFactory(factory.Factory):
    """User 엔티티 팩토리 (auth 하네스용)."""

    class Meta:
        model = User

    id = factory.Sequence(lambda n: f"u{n}")
    provider = "mock"
    sub = factory.Sequence(lambda n: f"sub-{n}")
    email = factory.Faker("email")
    name = factory.Faker("name")
    roles = factory.LazyFunction(list)
