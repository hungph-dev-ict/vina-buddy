from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(
        ...,
        description="Overall backend health status",
        examples=["healthy"],
    )
    ollama: str = Field(
        ...,
        description="Ollama connectivity status",
        examples=["connected", "disconnected"],
    )
    version: str = Field(
        ...,
        description="Backend application version",
        examples=["0.1.0"],
    )
