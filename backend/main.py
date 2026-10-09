import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import products, boiler, standardization, lab, dashboard, dg_hsd

app = FastAPI(
    title="CASEYA Dairy Plant Operations API",
    description="High-precision industrial dairy calculation and daily operations API for CASEYA.",
    version="1.0.0"
)

# CORS Middleware (allows Flutter Web local and Vercel domains)
origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Routers
app.include_router(products.router, prefix="/api/v1")
app.include_router(boiler.router, prefix="/api/v1")
app.include_router(dg_hsd.router, prefix="/api/v1")
app.include_router(standardization.router, prefix="/api/v1")
app.include_router(lab.router, prefix="/api/v1")
app.include_router(dashboard.router, prefix="/api/v1")

@app.get("/")
def root():
    return {
        "app": "CASEYA Dairy Plant Operations & Calculation System",
        "status": "online",
        "version": "1.0.0",
        "api_docs": "/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "caseya-plant-backend"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
