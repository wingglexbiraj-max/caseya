from fastapi import APIRouter
from models import DashboardStatsResponse

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("", response_model=DashboardStatsResponse)
def get_dashboard_summary():
    return {
        "today_production_litres": 18450.0,
        "today_dispatch_litres": 16200.0,
        "current_stock_litres": 42800.0,
        "today_boiler_consumption_litres": 900.0,
        "today_standardization_batches": 2,
        "system_status": "Facility Online • All Units Operational"
    }
