from fastapi import APIRouter, Depends, HTTPException


router = APIRouter()

@router.post("/alive")
def is_alive():
    return {"status": "alive"}

@router.get("/ready")
def is_ready():
    return {"status": "ready"}
