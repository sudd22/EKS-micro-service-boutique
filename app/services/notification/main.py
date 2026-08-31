import asyncio
import logging
from contextlib import asynccontextmanager

from app.services.notification import models
from app.services.notification.consumer import consume_forever
from app.services.notification.routes import router
from app.shared.db import init_models
from fastapi import FastAPI

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("notification")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_models()
    stop_event = asyncio.Event()
    consumer_task = asyncio.create_task(consume_forever(stop_event))
    yield
    stop_event.set()
    consumer_task.cancel()
    try:
        await consumer_task
    except asyncio.CancelledError:
        pass


app = FastAPI(title="Notification Service", version="1.0.0", lifespan=lifespan)
app.include_router(router)


@app.get("/health", tags=["system"])
async def health():
    return {"status": "healthy", "service": "notification"}
