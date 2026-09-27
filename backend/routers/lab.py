from fastapi import APIRouter
from typing import Optional
from models import LabRecordSchema

router = APIRouter(prefix="/lab", tags=["Quality Control Lab"])

@router.get("/today", response_model=Optional[LabRecordSchema])
def get_today_lab_data(date: Optional[str] = None):
    # Returns morning QC lab testing record
    return {
        "record_id": "LAB-2026-0927-01",
        "date": date or "2026-09-27",
        "sample_time": "08:30 AM",
        "batch_or_silo_no": "Raw Milk Silo #02",
        "milk_quantity": 12500.0,
        "fat_percent": 4.20,
        "snf_percent": 8.65,
        "clr": 29.5,
        "acidity": 0.13,
        "temperature": 4.2,
        "analyst_name": "P. Sharma (Sr. Chemist)",
        "remarks": "Fresh Morning Procurement Tanker Batch #TB-402"
    }
