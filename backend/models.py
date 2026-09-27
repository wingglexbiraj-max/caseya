from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class ProductSchema(BaseModel):
    product_id: str
    product_name: str
    item_code: Optional[str] = "NA"
    short_code: Optional[str] = ""
    category: str
    unit: str
    pack_size: float
    pack_size_display: str
    pieces_per_crate: int
    per_crate_qty: Optional[float] = None
    per_crate_qty_grams: Optional[float] = None
    per_crate_display: Optional[str] = None
    price_per_piece: Optional[float] = 0.0
    shelf_life: Optional[str] = "12 Days"
    allowed_input_modes: List[str]
    target_fat: Optional[float] = None
    target_snf: Optional[float] = None
    active: bool = True

class BoilerCalculateRequest(BaseModel):
    opening_cm: float = Field(..., ge=0)
    closing_cm: float = Field(..., ge=0)
    running_hours: float = Field(..., ge=0)
    fuel_top_up: float = Field(default=0.0, ge=0)
    include_top_up_in_net: bool = True

class BoilerCalculationResponse(BaseModel):
    opening_cm: float
    closing_cm: float
    level_difference_cm: float
    calculated_level_consumption: float
    fuel_top_up: float
    net_reported_consumption: float
    running_hours: float
    consumption_per_hour: float

class BoilerRecordSchema(BaseModel):
    record_id: str
    date: str
    time: str
    shift: str
    employee_id: str
    employee_name: str
    opening_cm: float
    closing_cm: float
    level_difference_cm: float
    calculated_level_consumption: float
    fuel_top_up: float
    net_reported_consumption: float
    running_hours: float
    consumption_per_hour: float
    remarks: str = ""
    created_at: Optional[datetime] = None

class StandardizationCalculateRequest(BaseModel):
    milk_quantity: float = Field(..., gt=0)
    milk_fat: float = Field(..., gt=0, le=15.0)
    milk_snf: float = Field(..., gt=0, le=16.0)
    target_product: str
    target_fat: float = Field(..., ge=0)
    target_snf: float = Field(..., ge=0)
    smp_snf_ratio: float = 96.0
    sugar_percent: float = 0.0

class StandardizationCalculationResponse(BaseModel):
    initial_quantity: float
    initial_fat: float
    initial_snf: float
    target_fat: float
    target_snf: float
    water_required: float
    smp_required: float
    sugar_required: float
    final_quantity: float
    final_fat: float
    final_snf: float
    formula_version: str

class StandardizationRecordSchema(BaseModel):
    record_id: str
    date: str
    time: str
    employee_id: str
    employee_name: str
    input_milk_quantity: float
    input_unit: str = "Litres"
    input_fat: float
    input_snf: float
    target_product_id: str
    target_product_name: str
    target_fat: float
    target_snf: float
    water_required: float
    smp_required: float
    sugar_required: float
    final_quantity: float
    final_fat: float
    final_snf: float
    calculation_formula_version: str
    notes: str = ""
    created_at: Optional[datetime] = None

class LabRecordSchema(BaseModel):
    record_id: str
    date: str
    sample_time: str
    batch_or_silo_no: str
    milk_quantity: float
    fat_percent: float
    snf_percent: float
    clr: float
    acidity: float
    temperature: float
    analyst_name: str
    remarks: str = ""

class DashboardStatsResponse(BaseModel):
    today_production_litres: float
    today_dispatch_litres: float
    current_stock_litres: float
    today_boiler_consumption_litres: float
    today_standardization_batches: int
    system_status: str
