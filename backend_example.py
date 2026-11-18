#!/usr/bin/env python3
"""
Script de lancement du backend Python - Exemple FastAPI

Assurez-vous que les dépendances sont installées:
pip install -r requirements.txt

Puis lancez ce script:
python3 backend_example.py
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import json
import os
from pathlib import Path

# Initialisation FastAPI
app = FastAPI(title="Green App Backend", version="1.0.0")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:*", "http://192.168.1.*", "http://127.0.0.1:*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models Pydantic
class DetectionResult(BaseModel):
    diseaseId: str
    diseaseName: str
    confidence: float
    description: str
    treatments: List[str]
    severity: str  # low, moderate, high
    detectionDate: str

class ChatMessage(BaseModel):
    message: str
    context: Optional[dict] = None
    image_url: Optional[str] = None

class ChatResponse(BaseModel):
    id: str
    response: str
    image_url: Optional[str] = None

class MessageHistory(BaseModel):
    id: str
    content: str
    isUser: bool
    timestamp: str
    imageUrl: Optional[str] = None

# Stockage en mémoire (à remplacer par une vraie BD)
detection_history = []
chat_history = []

# Endpoints Vision
@app.post("/api/vision/detect", response_model=DetectionResult)
async def detect_disease(file: UploadFile = File(...)):
    """
    Détecte les maladies des plantes à partir d'une image.
    """
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Format de fichier invalide")
    
    try:
        # Sauvegarder l'image
        upload_dir = Path("uploads")
        upload_dir.mkdir(exist_ok=True)
        
        filepath = upload_dir / file.filename
        with open(filepath, "wb") as f:
            f.write(await file.read())
        
        # TODO: Exécuter le modèle IA
        # prediction = model.predict(filepath)
        
        result = DetectionResult(
            diseaseId="oïdium_001",
            diseaseName="Oïdium",
            confidence=0.92,
            description="Revêtement blanc poudré sur les feuilles",
            treatments=[
                "Pulvériser du soufre",
                "Utiliser un fongicide",
                "Améliorer la ventilation"
            ],
            severity="moderate",
            detectionDate=datetime.now().isoformat() + "Z"
        )
        
        detection_history.append(result.dict())
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/vision/history", response_model=List[DetectionResult])
async def get_detection_history(limit: int = 50, offset: int = 0):
    """
    Récupère l'historique des détections.
    """
    start = offset
    end = offset + limit
    return detection_history[start:end]

# Endpoints Chatbot
@app.post("/api/chat/message", response_model=ChatResponse)
async def send_message(msg: ChatMessage):
    """
    Envoie un message au chatbot et reçoit une réponse.
    """
    if not msg.message:
        raise HTTPException(status_code=400, detail="Message vide")
    
    try:
        # TODO: Exécuter le modèle chatbot
        # response_text = chatbot_model.generate_response(msg.message, msg.context)
        
        response_text = (
            "Pour arroser correctement, vérifiez que le sol est sec avant chaque arrosage. "
            "Généralement, une fois par semaine suffit. Adaptez en fonction de l'humidité "
            "de votre environnement et du type de plante."
        )
        
        response_id = f"msg_{datetime.now().timestamp()}"
        
        response = ChatResponse(
            id=response_id,
            response=response_text,
            image_url=None
        )
        
        # Sauvegarder dans l'historique
        chat_history.append(MessageHistory(
            id=f"user_{response_id}",
            content=msg.message,
            isUser=True,
            timestamp=datetime.now().isoformat(),
            imageUrl=msg.image_url
        ).dict())
        
        chat_history.append(MessageHistory(
            id=response_id,
            content=response_text,
            isUser=False,
            timestamp=datetime.now().isoformat(),
            imageUrl=None
        ).dict())
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/chat/history", response_model=List[MessageHistory])
async def get_chat_history(limit: int = 100, offset: int = 0):
    """
    Récupère l'historique des messages.
    """
    start = offset
    end = offset + limit
    return chat_history[start:end]

@app.delete("/api/chat/history")
async def clear_chat_history():
    """
    Efface l'historique de conversation.
    """
    chat_history.clear()
    return {"message": "Historique effacé"}

# Health Check
@app.get("/health")
async def health_check():
    """
    Vérifie que le serveur est opérationnel.
    """
    return {
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Lancement du serveur Green App Backend...")
    print("📍 URL: http://localhost:8000")
    print("📚 Documentation: http://localhost:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
