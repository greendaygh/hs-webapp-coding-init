"""Motor 기반 User 저장소.

users 컬렉션, (provider, sub) 유니크 인덱스. 도메인 `User` ↔ Mongo 문서 매핑은 단순.
"""
from __future__ import annotations

from typing import Any

from motor.motor_asyncio import AsyncIOMotorDatabase

from {{app_module}}.domain.user import User


def _to_doc(user: User) -> dict[str, Any]:
    return {
        "_id": user.id,
        "provider": user.provider,
        "sub": user.sub,
        "email": user.email,
        "name": user.name,
        "roles": list(user.roles),
        "created_at": user.created_at,
    }


def _from_doc(doc: dict[str, Any]) -> User:
    return User(
        id=str(doc["_id"]),
        provider=str(doc["provider"]),
        sub=str(doc["sub"]),
        email=str(doc.get("email", "")),
        name=str(doc.get("name", "")),
        roles=list(doc.get("roles") or []),
        created_at=doc["created_at"],
    )


class MongoUserRepo:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self._coll = db["users"]

    async def ensure_indexes(self) -> None:
        await self._coll.create_index([("provider", 1), ("sub", 1)], unique=True)

    async def get_by_provider_sub(self, provider: str, sub: str) -> User | None:
        doc = await self._coll.find_one({"provider": provider, "sub": sub})
        return _from_doc(doc) if doc else None

    async def get_by_id(self, user_id: str) -> User | None:
        doc = await self._coll.find_one({"_id": user_id})
        return _from_doc(doc) if doc else None

    async def upsert(self, user: User) -> User:
        doc = _to_doc(user)
        await self._coll.replace_one({"_id": user.id}, doc, upsert=True)
        return user
