import os
import base64
import hashlib
from cryptography.fernet import Fernet

# Fallback development key: 32 bytes base64 encoded
DEV_KEY = "y3_h-H02b5y8pC0n4v7Z6e9T0u3I5o1L8a9E4r5D8wQ="
key_str = os.environ.get("ENCRYPTION_KEY", DEV_KEY)

try:
    key_decoded = base64.urlsafe_b64decode(key_str.encode('utf-8'))
    if len(key_decoded) != 32:
        # If length is not 32, hash it to 32 bytes and base64 encode it
        key_str = base64.urlsafe_b64encode(hashlib.sha256(key_str.encode('utf-8')).digest()).decode('utf-8')
except Exception:
    # Hash and encode on any decoding error
    key_str = base64.urlsafe_b64encode(hashlib.sha256(key_str.encode('utf-8')).digest()).decode('utf-8')

fernet = Fernet(key_str.encode('utf-8'))

def encrypt_data(value: str) -> str:
    """Encrypts a string using Fernet symmetric encryption."""
    if not value:
        return value
    return fernet.encrypt(value.encode('utf-8')).decode('utf-8')

def decrypt_data(value: str) -> str:
    """Decrypts a Fernet encrypted string. Returns raw value on failure."""
    if not value:
        return value
    try:
        return fernet.decrypt(value.encode('utf-8')).decode('utf-8')
    except Exception:
        # Return as is if decryption fails (e.g. if it was saved as plain text)
        return value

def hash_data(value: str) -> str:
    """Hashes a string (like CPF or Email) using SHA-256 for secure database index lookups."""
    if not value:
        return value
    # Normalize CPF or Email (strip whitespace and lowercase)
    normalized = value.strip().lower()
    # Remove CPF symbols for consistent hashing
    normalized = normalized.replace('.', '').replace('-', '').replace('/', '')
    return hashlib.sha256(normalized.encode('utf-8')).hexdigest()
