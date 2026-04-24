from hashlib import sha256
from dataclasses import dataclass

from google.cloud import storage

from fiscore_backend.config import get_settings


@dataclass(frozen=True)
class RawArtifactPath:
    bucket: str
    path: str

    @property
    def uri(self) -> str:
        return f"gs://{self.bucket}/{self.path}"


class RawArtifactStorage:
    def __init__(self) -> None:
        settings = get_settings()
        self.bucket_name = settings.raw_artifact_bucket
        self.client = storage.Client(project=settings.gcp_project_id)

    def build_html_path(self, source_slug: str, scrape_run_id: str, filename: str) -> RawArtifactPath:
        path = f"raw/html/{source_slug}/{scrape_run_id}/{filename}"
        return RawArtifactPath(bucket=self.bucket_name, path=path)

    def bucket_exists(self) -> bool:
        bucket = self.client.lookup_bucket(self.bucket_name)
        return bucket is not None

    def upload_text(self, artifact: RawArtifactPath, content: str, content_type: str = "text/html") -> str:
        bucket = self.client.bucket(self.bucket_name)
        blob = bucket.blob(artifact.path)
        blob.upload_from_string(content, content_type=content_type)
        return artifact.uri


def hash_text(content: str) -> str:
    return sha256(content.encode("utf-8")).hexdigest()
