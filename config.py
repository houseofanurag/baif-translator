# BAIF Translator Configuration
import os

class Config:
    APP_TITLE = "BAIF Offline Translator"
    
    # CHANGED: 0.0.0.0 allows other local network devices (tablets/phones) to connect to this machine
    HOST = "0.0.0.0" 
    PORT = 8000
    DEBUG = False  # Production default for field deployments
    
    # Model Settings
    WHISPER_MODEL = "mlx-community/whisper-base-mlx"
    
    # Increased text length limits for longer field audio/video logs
    MAX_TEXT_LENGTH = 2000 
    
    # Paths (Absolute pathways protect against relative execution errors)
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
    OUTPUT_DIR = os.path.join(BASE_DIR, "outputs")
    
    # Supported Languages
    LANGUAGES = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi"
    }