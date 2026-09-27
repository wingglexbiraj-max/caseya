from fastapi import APIRouter
from typing import List
from models import ProductSchema

router = APIRouter(prefix="/products", tags=["Products"])

# In-memory initial data store (backed by Google Sheets or PostgreSQL)
PRODUCTS_STORE: List[dict] = [
    {
        "product_id": "PRD-001",
        "product_name": "Purabi Plus Milk 500 ml",
        "category": "Milk",
        "unit": "ml",
        "pack_size": 500.0,
        "pack_size_display": "500 ml",
        "pieces_per_crate": 20,
        "allowed_input_modes": ["Pieces", "Crates", "Litres"],
        "target_fat": 4.5,
        "target_snf": 8.5,
        "active": True
    },
    {
        "product_id": "PRD-002",
        "product_name": "Purabi Plus Milk 250 ml",
        "category": "Milk",
        "unit": "ml",
        "pack_size": 250.0,
        "pack_size_display": "250 ml",
        "pieces_per_crate": 40,
        "allowed_input_modes": ["Pieces", "Crates", "Litres"],
        "target_fat": 4.5,
        "target_snf": 8.5,
        "active": True
    },
    {
        "product_id": "PRD-003",
        "product_name": "Curd Pouch 400 g",
        "category": "Curd",
        "unit": "g",
        "pack_size": 400.0,
        "pack_size_display": "400 g",
        "pieces_per_crate": 25,
        "allowed_input_modes": ["Pieces", "Crates", "Kg"],
        "target_fat": 3.2,
        "target_snf": 9.5,
        "active": True
    },
    {
        "product_id": "PRD-004",
        "product_name": "Sweet Curd Cup 80 g",
        "category": "Curd",
        "unit": "g",
        "pack_size": 80.0,
        "pack_size_display": "80 g",
        "pieces_per_crate": 50,
        "allowed_input_modes": ["Pieces", "Crates", "Kg"],
        "target_fat": 3.5,
        "target_snf": 10.0,
        "active": True
    },
    {
        "product_id": "PRD-005",
        "product_name": "Lassi 200 ml",
        "category": "Fermented",
        "unit": "ml",
        "pack_size": 200.0,
        "pack_size_display": "200 ml",
        "pieces_per_crate": 30,
        "allowed_input_modes": ["Pieces", "Crates", "Litres"],
        "target_fat": 2.5,
        "target_snf": 9.0,
        "active": True
    },
    {
        "product_id": "PRD-006",
        "product_name": "Toned Milk 500 ml",
        "category": "Milk",
        "unit": "ml",
        "pack_size": 500.0,
        "pack_size_display": "500 ml",
        "pieces_per_crate": 20,
        "allowed_input_modes": ["Pieces", "Crates", "Litres"],
        "target_fat": 3.0,
        "target_snf": 8.5,
        "active": True
    }
]

@router.get("", response_model=List[ProductSchema])
def get_products():
    return PRODUCTS_STORE

@router.post("", response_model=ProductSchema)
def create_product(product: ProductSchema):
    PRODUCTS_STORE.append(product.model_dump())
    return product
