from pydantic import BaseModel, field_validator, model_validator
from typing import List


class GarmentCreate(BaseModel):
    name: str
    brand: str = ""
    colors: List[str] = []  # Support pour plusieurs couleurs
    color: str = ""  # Compatibilité avec l'ancien format
    category: str
    image_url: str = ""

    @model_validator(mode='before')
    @classmethod
    def validate_colors(cls, data):
        if isinstance(data, dict):
            # Si colors n'est pas fourni mais color l'est, convertir color en liste
            if "colors" not in data or not data.get("colors"):
                if "color" in data and data["color"]:
                    data["colors"] = [data["color"]]
                elif "colors" not in data:
                    data["colors"] = []
            # Si color n'est pas fourni mais colors l'est, utiliser la première couleur
            if not data.get("color") and data.get("colors"):
                data["color"] = data["colors"][0] if data["colors"] else ""
        return data


class GarmentUpdate(BaseModel):
    name: str | None = None
    brand: str | None = None
    colors: List[str] | None = None
    color: str | None = None  # Compatibilité
    category: str | None = None
    image_url: str | None = None


class GarmentOut(BaseModel):
    id: str
    user_id: str
    name: str
    brand: str = ""
    colors: List[str] = []  # Nouveau format
    color: str = ""  # Compatibilité avec l'ancien format (première couleur ou vide)
    category: str = ""
    image_url: str = ""
    created_at: str = ""
    times_worn: int = 0

    @model_validator(mode='before')
    @classmethod
    def set_color_from_colors(cls, data):
        if isinstance(data, dict):
            # Migration depuis l'ancien format
            if "colors" not in data or not data.get("colors"):
                if "color" in data and data["color"]:
                    data["colors"] = [data["color"]]
                elif "colors" not in data:
                    data["colors"] = []
            # Assurer que color existe pour compatibilité
            if not data.get("color") and data.get("colors"):
                data["color"] = data["colors"][0] if data["colors"] else ""
            elif "color" not in data:
                data["color"] = ""
        return data
