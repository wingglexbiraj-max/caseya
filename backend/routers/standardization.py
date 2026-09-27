from fastapi import APIRouter
from typing import List
from models import (
    StandardizationCalculateRequest,
    StandardizationCalculationResponse,
    StandardizationRecordSchema
)
from services.standardization_service import StandardizationCalculationService

router = APIRouter(prefix="/standardization", tags=["Standardization"])

STANDARDIZATION_RECORDS: List[dict] = [
    {
        "record_id": "STD-20260927-01",
        "date": "2026-09-27",
        "time": "09:20 AM",
        "employee_id": "EMP-0104",
        "employee_name": "R. K. Baruah",
        "input_milk_quantity": 5000.0,
        "input_unit": "Litres",
        "input_fat": 3.8,
        "input_snf": 8.4,
        "target_product_id": "PRD-005",
        "target_product_name": "Lassi 200 ml",
        "target_fat": 2.5,
        "target_snf": 9.0,
        "water_required": 2600.0,
        "smp_required": 275.0,
        "sugar_required": 608.0,
        "final_quantity": 8213.0,
        "final_fat": 2.45,
        "final_snf": 9.02,
        "calculation_formula_version": "v1.2-Standard-Dairy-MassBalance",
        "notes": "Morning batch"
    }
]

@router.post("/calculate", response_model=StandardizationCalculationResponse)
def calculate_standardization(req: StandardizationCalculateRequest):
    return StandardizationCalculationService.calculate(
        milk_quantity=req.milk_quantity,
        milk_fat=req.milk_fat,
        milk_snf=req.milk_snf,
        target_product=req.target_product,
        target_fat=req.target_fat,
        target_snf=req.target_snf,
        smp_snf_ratio=req.smp_snf_ratio,
        sugar_percent=req.sugar_percent
    )

@router.get("", response_model=List[StandardizationRecordSchema])
def get_standardization_records():
    return STANDARDIZATION_RECORDS

@router.post("", response_model=StandardizationRecordSchema)
def save_standardization_record(record: StandardizationRecordSchema):
    STANDARDIZATION_RECORDS.insert(0, record.model_dump())
    return record
