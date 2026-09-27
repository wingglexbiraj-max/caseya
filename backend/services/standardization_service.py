class StandardizationCalculationService:
    FORMULA_VERSION = "v1.2-Standard-Dairy-MassBalance"

    @staticmethod
    def calculate(milk_quantity: float, milk_fat: float, milk_snf: float, target_product: str, target_fat: float, target_snf: float, smp_snf_ratio: float = 96.0, sugar_percent: float = 0.0):
        # 1. Initial Solid Masses
        initial_fat_kg = (milk_quantity * milk_fat) / 100.0
        initial_snf_kg = (milk_quantity * milk_snf) / 100.0

        water_required = 0.0
        smp_required = 0.0
        sugar_required = 0.0
        final_quantity = milk_quantity

        # 2. Fat Standardization
        if target_fat > 0.0 and milk_fat > target_fat:
            target_vol_for_fat = initial_fat_kg / (target_fat / 100.0)
            water_required = max(0.0, target_vol_for_fat - milk_quantity)
            final_quantity = milk_quantity + water_required

        # 3. SNF Standardization
        target_snf_kg = (final_quantity * target_snf) / 100.0
        snf_deficit_kg = target_snf_kg - initial_snf_kg

        if snf_deficit_kg > 0.0:
            smp_required = snf_deficit_kg / (smp_snf_ratio / 100.0)

        # 4. Sugar Addition
        is_sweetened = "lassi" in target_product.lower() or "sweet" in target_product.lower()
        effective_sugar_pct = sugar_percent if sugar_percent > 0.0 else (8.0 if is_sweetened else 0.0)

        if effective_sugar_pct > 0.0:
            sugar_required = (final_quantity * effective_sugar_pct) / 100.0
            final_quantity += (sugar_required * 0.63)

        # 5. Final Calculated Values
        final_fat = ((initial_fat_kg + (smp_required * 0.005)) / final_quantity) * 100.0 if final_quantity > 0 else 0.0
        final_snf = ((initial_snf_kg + (smp_required * (smp_snf_ratio / 100.0))) / final_quantity) * 100.0 if final_quantity > 0 else 0.0

        return {
            "initial_quantity": milk_quantity,
            "initial_fat": milk_fat,
            "initial_snf": milk_snf,
            "target_fat": target_fat,
            "target_snf": target_snf,
            "water_required": round(water_required, 2),
            "smp_required": round(smp_required, 2),
            "sugar_required": round(sugar_required, 2),
            "final_quantity": round(final_quantity, 2),
            "final_fat": round(final_fat, 2),
            "final_snf": round(final_snf, 2),
            "formula_version": StandardizationCalculationService.FORMULA_VERSION
        }
