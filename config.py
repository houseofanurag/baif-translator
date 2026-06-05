# BAIF Translator Configuration

class Config:
    APP_TITLE = "BAIF Offline Translator"
    HOST = "127.0.0.1"
    PORT = 8000
    DEBUG = True
    
    # Model Settings
    WHISPER_MODEL = "mlx-community/whisper-base-mlx"
    MAX_TEXT_LENGTH = 400
    
    # Paths
    UPLOAD_DIR = "uploads"
    OUTPUT_DIR = "outputs"
    
    # Supported Languages
    LANGUAGES = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi"
    }
