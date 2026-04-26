"""Motor 기반 Session 저장소.

sessions 컬렉션, expires_at 에 TTL 인덱스로 자동 만료.
"""
from __future__ import annotations

from typing import Any

from motor.motor_asyncio import AsyncIOMotorDatabase

from {{app_module}}.domain.user import Session


def _to_doc(session: Session) -> dict[str, Any]:
    return {
        "_id": session.id,
        "user_id": session.user_id,
        "expires_at": session.expires_at,
        "created_at": session.created_at,
    }


def _from_doc(doc: dict[str, Any]) -> Session:
    return Session(
        id=str(doc["_id"]),
        user_id=str(doc["user_id"]),
        expires_at=doc["expires_at"],
        created_at=doc["created_at"],
    )


class MongoSessionRepo:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self._coll = db["sessions"]

    async def ensure_indexes(self) -> None:
        await self._coll.create_index("expires_at", expireAfterSeconds=0)

    async def create(self, session: Session) -> None:
        await self._coll.insert_one(_to_doc(session))

    async def get(self, sid: str) -> Session | None:
        doc = await self._coll.find_one({"_id": sid})
        return _from_doc(doc) if doc else None

    async def delete(self, sid: str) -> None:
        await self._coll.delete_one({"_id": sid})
