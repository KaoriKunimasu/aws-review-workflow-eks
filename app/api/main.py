from fastapi import Depends, FastAPI, Query
from fastapi.responses import JSONResponse

from app.api import service
from app.api.deps import get_current_user_id
from app.api.schemas import CreateReviewRequest, UpdateStatusRequest

app = FastAPI(title="Review Workflow API", version="1.0.0")


@app.exception_handler(service.ServiceError)
async def service_error_handler(request, exc: service.ServiceError):
    # Translate the service-layer error into a JSON HTTP response.
    body = {"message": exc.message}
    if exc.details:
        body["details"] = exc.details
    return JSONResponse(status_code=exc.status_code, content=body)


@app.get("/health")
def health():
    # Used by container HEALTHCHECK and (later) Kubernetes probes.
    return {"status": "ok"}


@app.post("/reviews", status_code=201)
def create_review(
    payload: CreateReviewRequest,
    user_id: str = Depends(get_current_user_id),
):
    item = service.create_review(payload.model_dump(), user_id)
    return {"message": "Workflow request created successfully.", "item": item}


@app.get("/reviews")
def list_reviews(
    limit: int = Query(default=20, ge=1, le=100),
    cursor: str | None = Query(default=None),
):
    return service.list_reviews(limit, cursor)


@app.get("/reviews/{request_id}")
def get_review(request_id: str):
    return {"item": service.get_review(request_id)}


@app.patch("/reviews/{request_id}/status")
def update_status(request_id: str, payload: UpdateStatusRequest):
    item = service.update_status(request_id, payload.model_dump())
    return {"message": "Workflow request status updated successfully.", "item": item}
