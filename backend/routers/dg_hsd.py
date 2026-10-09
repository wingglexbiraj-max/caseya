from fastapi import APIRouter
from typing import List
from models import DgHsdRecordSchema

router = APIRouter(prefix="/dg", tags=["DG HSD"])

DG_RECORDS: List[dict] = [
    {
        "record_id": "DG-20260928-A",
        "date": "2026-09-28",
        "time": "11:00 AM",
        "shift": "Shift A (06:00 - 14:00)",
        "employee_id": "EMP-001",
        "employee_name": "Biraj Goswami",
        "fuel_added": 200.0,
        "start_percentage": 85.0,
        "end_percentage": 62.0,
        "percentage_drop": 23.0,
        "fuel_consumption": 75.0,
        "kwh": 260.0,
        "running_hours": 4.5,
        "consumption_per_hour": 16.67,
        "units_per_litre": 3.47,
        "remarks": "DG operated smoothly during peak pasteurizer operation"
    },
    {
        "record_id": "DG-20260927-B",
        "date": "2026-09-27",
        "time": "07:30 PM",
        "shift": "Shift B (14:00 - 22:00)",
        "employee_id": "EMP-002",
        "employee_name": "M. Hazarika",
        "fuel_added": 0.0,
        "start_percentage": 62.0,
        "end_percentage": 48.0,
        "percentage_drop": 14.0,
        "fuel_consumption": 48.0,
        "kwh": 165.0,
        "running_hours": 3.0,
        "consumption_per_hour": 16.0,
        "units_per_litre": 3.44,
        "remarks": "Power grid cut from 17:30 to 20:30; cold room backup sustained"
    }
]

@router.get("", response_model=List[DgHsdRecordSchema])
def get_dg_records():
    return DG_RECORDS

@router.post("", response_model=DgHsdRecordSchema)
def save_dg_record(record: DgHsdRecordSchema):
    DG_RECORDS.insert(0, record.model_dump())
    return record

@router.put("/{record_id}", response_model=DgHsdRecordSchema)
def update_dg_record(record_id: str, record: DgHsdRecordSchema):
    for i, r in enumerate(DG_RECORDS):
        if r.get("record_id") == record_id:
            DG_RECORDS[i] = record.model_dump()
            return record
    DG_RECORDS.insert(0, record.model_dump())
    return record

@router.delete("/{record_id}")
def delete_dg_record(record_id: str):
    global DG_RECORDS
    DG_RECORDS = [r for r in DG_RECORDS if r.get("record_id") != record_id]
    return {"status": "success", "message": f"DG record {record_id} deleted"}
