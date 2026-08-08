import json
import os
from collections.abc import AsyncGenerator

import boto3
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import declarative_base


Base = declarative_base()


def _db_credentials() -> dict:

    if os.environ.get("DB_CREDENTIALS_SOURCE", "env") == "secretsmanager":
        sm = boto3.client(
            "secretsmanager",
            region_name=os.environ.get("AWS_DEFAULT_REGION", "eu-west-2"),
        )
        secret = sm.get_secret_value(SecretId=os.environ["DB_SECRET_ID"])
        return json.loads(secret["SecretString"])
    return {
        "username": os.environ["DB_USER"],
        "password": os.environ["DB_PASSWORD"],
        "host": os.environ["DB_HOST"],
        "port": os.environ.get("DB_PORT", "5432"),
        "dbname": os.environ["DB_NAME"],
    }


def make_engine() -> AsyncEngine:
    c = _db_credentials()
    schema = os.environ["DB_SCHEMA"]
    url = f"postgresql+asyncpg://{c['username']}:{c['password']}@{c['host']}:{c['port']}/{c['dbname']}"

    return create_async_engine(
        url,
        pool_size=int(os.environ.get("DB_POOL_SIZE", "5")),
        max_overflow=int(os.environ.get("DB_MAX_OVERFLOW", "10")),
        pool_pre_ping=True,
        connect_args={"server_settings": {"search_path": schema}},
    )


engine: AsyncEngine = make_engine()
SessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]:

    async with SessionLocal() as session:
        yield session


async def init_models() -> None:

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
