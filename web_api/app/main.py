from fastapi import FastAPI
from app.routes import simulation_routes


app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "Welcome to fake API"}


app.include_router(simulation_routes.router)
