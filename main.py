# main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from handler import EndpointHandler

app = FastAPI()
handler = EndpointHandler()

# CORS для локального теста и фронта
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/generate")
async def generate(request: Request):
    data = await request.json()
    result = handler(data)
    return result

@app.get("/")
def root():
    return {"status": "OK"}
