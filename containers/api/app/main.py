from fastapi import FastAPI

from config.settings import settings

# Since AWS ELB does not support path rewrite, we need to manually prefix routes
API_ROOT = "/api"


app = FastAPI(root_path="")


@app.get(API_ROOT + "/")
def api_index():
    print("SECRET_KEY", settings.SECRET_KEY)
    return {"status": "up", "DEBUG": settings.DEBUG}
