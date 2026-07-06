"""Tiny demo service for gcp-terraform-lab.

Exists so the Terraform environment has something real to deploy. The
APP_MESSAGE env var is injected from Secret Manager by Terraform, which lets
the lab demonstrate secret-backed configuration end to end.
"""

import os

from fastapi import FastAPI

app = FastAPI(title="tf-lab-api")


@app.get("/")
def root() -> dict:
    return {
        "service": "tf-lab-api",
        "message": os.getenv("APP_MESSAGE", "APP_MESSAGE not set"),
    }


# Note: this was originally /healthz, but Google Frontend intercepts that
# path on run.app URLs and returns its own 404 before the container sees it.
@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
