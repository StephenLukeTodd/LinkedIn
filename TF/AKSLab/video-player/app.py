import os
import random
from datetime import datetime, timedelta, timezone

from flask import Flask, jsonify, render_template
from azure.core.exceptions import AzureError
from azure.storage.blob import BlobServiceClient
from azure.storage.blob import generate_blob_sas, BlobSasPermissions

app = Flask(__name__)

AZURE_STORAGE_CONTAINER_NAME = os.getenv("AZURE_STORAGE_CONTAINER_NAME", "data")
AZURE_STORAGE_CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
AZURE_STORAGE_ACCOUNT_NAME = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
AZURE_STORAGE_ACCOUNT_ENDPOINT = os.getenv("AZURE_STORAGE_ACCOUNT_ENDPOINT")

_SAS_MINUTES = int(os.getenv("VIDEO_SAS_MINUTES", "60"))

_blob_service_client = None
_container_client = None


def _init_storage():
    global _blob_service_client, _container_client

    if _container_client is not None:
        return

    if not AZURE_STORAGE_CONNECTION_STRING:
        raise RuntimeError("AZURE_STORAGE_CONNECTION_STRING is required")

    _blob_service_client = BlobServiceClient.from_connection_string(AZURE_STORAGE_CONNECTION_STRING)
    _container_client = _blob_service_client.get_container_client(AZURE_STORAGE_CONTAINER_NAME)


def _account_name_from_client():
    if AZURE_STORAGE_ACCOUNT_NAME:
        return AZURE_STORAGE_ACCOUNT_NAME
    if _blob_service_client is not None:
        return _blob_service_client.account_name
    return None


def _account_key_from_conn_str(conn_str: str) -> str:
    parts = dict(
        tuple(p.split("=", 1))
        for p in conn_str.split(";")
        if p and "=" in p
    )
    key = parts.get("AccountKey")
    if not key:
        raise RuntimeError("AccountKey not found in AZURE_STORAGE_CONNECTION_STRING")
    return key


def _list_video_blobs():
    _init_storage()

    videos = []
    for blob in _container_client.list_blobs():
        name = blob.name
        if name.lower().endswith((".mp4", ".webm", ".mov", ".m4v")):
            videos.append(name)
    return videos


def _make_sas_url(blob_name: str) -> str:
    _init_storage()

    account_name = _account_name_from_client()
    if not account_name:
        raise RuntimeError("Could not determine storage account name")

    account_key = _account_key_from_conn_str(AZURE_STORAGE_CONNECTION_STRING)

    sas = generate_blob_sas(
        account_name=account_name,
        container_name=AZURE_STORAGE_CONTAINER_NAME,
        blob_name=blob_name,
        account_key=account_key,
        permission=BlobSasPermissions(read=True),
        expiry=datetime.now(timezone.utc) + timedelta(minutes=_SAS_MINUTES),
    )

    if AZURE_STORAGE_ACCOUNT_ENDPOINT:
        base = AZURE_STORAGE_ACCOUNT_ENDPOINT.rstrip("/")
        return f"{base}/{AZURE_STORAGE_CONTAINER_NAME}/{blob_name}?{sas}"

    return f"https://{account_name}.blob.core.windows.net/{AZURE_STORAGE_CONTAINER_NAME}/{blob_name}?{sas}"


@app.get("/")
def index():
    return render_template("index.html")


@app.get("/api/random")
def api_random():
    try:
        videos = _list_video_blobs()
        if not videos:
            return jsonify({"error": "No videos found in container"}), 404

        chosen = random.choice(videos)
        url = _make_sas_url(chosen)
        return jsonify({"name": chosen, "url": url})

    except (AzureError, RuntimeError, ValueError) as e:
        return jsonify({"error": str(e)}), 500


@app.get("/health")
def health():
    try:
        _init_storage()
        return jsonify({"status": "healthy"})
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
