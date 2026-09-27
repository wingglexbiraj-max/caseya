from fastapi import APIRouter
from typing import List
from models import BoilerCalculateRequest, BoilerCalculationResponse, BoilerRecordSchema
from services.boiler_service import BoilerCalculationService

router = APIRouter(prefix="/boiler", tags=["Boiler"])

BOILER_RECORDS: List[dict] = [
    {
        "record_id": "BLR-20260927-01",
        "date": "2026-09-27",
        "time": "02:00 PM",
        "shift": "Shift A (06:00 - 14:00)",
        "employee_id": "EMP-0104",
        "employee_name": "R. K. Baruah",
        "opening_cm": 500.0,
        "closing_cm": 430.0,
        "level_difference_cm": 70.0,
        "calculated_level_consumption": 900.0,
        "fuel_top_up": 0.0,
        "net_reported_consumption": 900.0,
        "running_hours": 8.5,
        "consumption_per_hour": 105.88,
        "remarks": "Normal operation morning pasteurizer run"
    }
]

@router.post("/calculate", response_model=BoilerCalculationResponse)
def calculate_boiler(req: BoilerCalculateRequest):
    return BoilerCalculationService.calculate(
        opening_cm=req.opening_cm,
        closing_cm=req.closing_cm,
        running_hours=req.running_hours,
        fuel_top_up=req.fuel_top_up,
        include_top_up_in_net=req.include_top_up_in_net
    )

@router.get("", response_model=List[BoilerRecordSchema])
def get_boiler_records():
    return BOILER_RECORDS

@router.post("", response_model=BoilerRecordSchema)
def save_boiler_record(record: BoilerRecordSchema):
    BOILER_RECORDS.insert(0, record.model_dump())
    return record
