from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    ENVIRONMENT: str = "local"


    JWT_SECRET_KEY: str = "local_development_only_secret_key_987654321"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24


    AWS_DEFAULT_REGION: str = "eu-west-2"
    AWS_ENDPOINT_URL: str | None = None
    SQS_QUEUE_NAME: str = "order-completed"


    PRODUCT_SERVICE_URL: str = "http://product-svc.prod.svc.cluster.local"
    PRODUCT_STOCK_TIMEOUT_SECONDS: float = 2.0


settings = Settings()
