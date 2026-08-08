import logging
from contextlib import asynccontextmanager

from app.services.payment import models
from app.services.payment.routes import router
from app.shared.db import init_models
from fastapi import FastAPI

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("payment")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_models()
    yield


app = FastAPI(title="Payment Service", version="1.0.0", lifespan=lifespan)
app.include_router(router)


@app.get("/health", tags=["system"])
async def health():
    return {"status": "healthy", "service": "payment"}
