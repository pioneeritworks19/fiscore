from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = Field(default="local", alias="APP_ENV")
    api_host: str = Field(default="0.0.0.0", alias="API_HOST")
    api_port: int = Field(default=8000, alias="API_PORT")
    worker_host: str = Field(default="0.0.0.0", alias="WORKER_HOST")
    worker_port: int = Field(default=8080, alias="WORKER_PORT")

    gcp_project_id: str = Field(alias="GCP_PROJECT_ID")
    gcp_region: str = Field(alias="GCP_REGION")
    raw_artifact_bucket: str = Field(alias="RAW_ARTIFACT_BUCKET")
    cloud_sql_connection_name: str | None = Field(default=None, alias="CLOUD_SQL_CONNECTION_NAME")
    cloud_sql_socket_dir: str = Field(default="/cloudsql", alias="CLOUD_SQL_SOCKET_DIR")

    db_host: str = Field(alias="DB_HOST")
    db_port: int = Field(default=5432, alias="DB_PORT")
    db_name: str = Field(alias="DB_NAME")
    db_user: str = Field(alias="DB_USER")
    db_password: str = Field(alias="DB_PASSWORD")

    default_parser_version: str = Field(default="sword-v1", alias="DEFAULT_PARSER_VERSION")

    @property
    def database_connection_kwargs(self) -> dict[str, str | int]:
        kwargs: dict[str, str | int] = {
            "dbname": self.db_name,
            "user": self.db_user,
            "password": self.db_password,
            "port": self.db_port,
        }

        if self.cloud_sql_connection_name:
            kwargs["host"] = f"{self.cloud_sql_socket_dir}/{self.cloud_sql_connection_name}"
        else:
            kwargs["host"] = self.db_host

        return kwargs


@lru_cache
def get_settings() -> Settings:
    return Settings()
