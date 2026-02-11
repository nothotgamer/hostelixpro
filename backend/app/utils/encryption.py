"""
Encryption utility for backups
"""
import os
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

class BackupEncryption:
    """
    Handles AES-256-GCM encryption for backup files
    """
    
    @staticmethod
    def generate_key():
        """Generate a random 32-byte key"""
        return AESGCM.generate_key(bit_length=256)
    
    @staticmethod
    def key_to_string(key):
        """Convert bytes key to base64 string"""
        return base64.b64encode(key).decode('utf-8')
        
    @staticmethod
    def key_from_string(key_str):
        """Convert base64 string to bytes key"""
        return base64.b64decode(key_str)

    @staticmethod
    def encrypt_file(file_path, output_path, key):
        """
        Encrypt a file using AES-GCM
        Appends nonce (12 bytes) to the beginning of the file
        """
        aesgcm = AESGCM(key)
        nonce = os.urandom(12)
        
        with open(file_path, 'rb') as f:
            data = f.read()
            
        ciphertext = aesgcm.encrypt(nonce, data, None)
        
        with open(output_path, 'wb') as f:
            f.write(nonce + ciphertext)
            
    @staticmethod
    def decrypt_file(file_path, output_path, key):
        """
        Decrypt a file using AES-GCM
        Reads nonce from the beginning of the file
        """
        aesgcm = AESGCM(key)
        
        with open(file_path, 'rb') as f:
            content = f.read()
            
        nonce = content[:12]
        ciphertext = content[12:]
        
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
        
        with open(output_path, 'wb') as f:
            f.write(plaintext)
