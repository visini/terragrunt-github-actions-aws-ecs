from pydantic import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):

    # * SECRETS
    # ---
    SECRET_KEY: str

    # * ENVIRONMENT VARIABLES
    # ---
    ENVIRONMENT: str
    DEBUG: str

    class Config:
        case_sensitive = True
        # env_file = ".env"
        # env_file_encoding = "utf-8"


@lru_cache()
def cached_settings():
    return Settings()


settings = cached_settings()
