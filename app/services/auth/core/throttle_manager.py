import asyncio
import logging
import os
import time
from collections import deque

import boto3
from app.shared.config import settings

logger = logging.getLogger("auth.throttle")

THROTTLE_TABLE_NAME = os.environ.get("THROTTLE_TABLE_NAME", "ai-throttle-config")
POLL_INTERVAL_SECONDS = 10


def throttle_enabled() -> bool:

    flag = os.environ.get("THROTTLE_ENABLED")
    if flag is not None:
        return flag.lower() in ("1", "true", "yes", "on")
    return os.environ.get("DB_CREDENTIALS_SOURCE", "env") == "secretsmanager"


class ThrottleManager:
    def __init__(self) -> None:

        self.active_throttles: dict[str, int] = {}
        self.table_name = THROTTLE_TABLE_NAME
        self._table = None
        self._recent_hits: dict[str, deque] = {}

    def _get_table(self):

        if self._table is None:
            resource = boto3.resource(
                "dynamodb",
                region_name=settings.AWS_DEFAULT_REGION,
                endpoint_url=settings.AWS_ENDPOINT_URL,
            )
            self._table = resource.Table(self.table_name)
        return self._table

    async def poll_forever(self, stop_event: asyncio.Event) -> None:

        while not stop_event.is_set():
            try:
                response = await asyncio.to_thread(self._get_table().scan)
                now = int(time.time())
                self.active_throttles = {
                    item["TargetEndpoint"]: int(item["MaxRequestsPerMinute"])
                    for item in response.get("Items", [])


                    if int(item.get("ExpiresAt", 0)) > now
                }
            except Exception as exc:
                logger.warning("Throttle poll failed: %s", exc)

            try:
                await asyncio.wait_for(stop_event.wait(), timeout=POLL_INTERVAL_SECONDS)
            except asyncio.TimeoutError:
                pass

    def is_blocked(self, path: str) -> bool:

        limit = self.active_throttles.get(path)
        if limit is None:
            return False
        hits = self._recent_hits.setdefault(path, deque())
        now = time.time()
        while hits and hits[0] < now - 60:
            hits.popleft()
        if len(hits) >= limit:
            return True
        hits.append(now)
        return False


manager = ThrottleManager()
