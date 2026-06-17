from typing import Optional

from pydantic import BaseModel, Field


class CreateReviewRequest(BaseModel):
    title: str = Field(min_length=1)
    requestType: str = Field(min_length=1)
    sourceLanguage: str = Field(min_length=1)
    targetLanguage: str = Field(min_length=1)
    sourceText: str = Field(min_length=1)
    targetText: Optional[str] = None
    category: Optional[str] = None
    reviewerNote: Optional[str] = None


class UpdateStatusRequest(BaseModel):
    status: str = Field(min_length=1)
    reviewerNote: Optional[str] = None


class ReviewItem(BaseModel):
    requestId: str
    title: str
    requestType: str
    sourceLanguage: str
    targetLanguage: str
    sourceText: str = ""
    targetText: str = ""
    category: str = ""
    status: str
    reviewerNote: str = ""
    createdBy: str
    createdAt: str
    updatedAt: str
