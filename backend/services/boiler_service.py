class BoilerCalculationService:
    @staticmethod
    def calculate(opening_cm: float, closing_cm: float, running_hours: float, fuel_top_up: float = 0.0, include_top_up_in_net: bool = True):
        diff_cm = opening_cm - closing_cm
        # Formula: ((Opening CM - Closing CM) * 900) / 70
        level_consumption = (diff_cm * 900.0) / 70.0 if diff_cm > 0 else 0.0
        
        net_consumption = (level_consumption + fuel_top_up) if include_top_up_in_net else level_consumption
        c_per_hour = (net_consumption / running_hours) if running_hours > 0 else 0.0

        return {
            "opening_cm": opening_cm,
            "closing_cm": closing_cm,
            "level_difference_cm": diff_cm,
            "calculated_level_consumption": round(level_consumption, 2),
            "fuel_top_up": fuel_top_up,
            "net_reported_consumption": round(net_consumption, 2),
            "running_hours": running_hours,
            "consumption_per_hour": round(c_per_hour, 2)
        }
