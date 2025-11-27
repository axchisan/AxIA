"""
Script para obtener el Refresh Token de Google OAuth 2.0

Este script te ayudará a obtener el refresh token necesario para que
AxIA pueda acceder a tu Google Calendar y Tasks sin intervención manual.

Requisitos:
- credentials.json (descargado de Google Cloud Console)
- Dependencias de Google instaladas (ver requirements.txt)

Uso:
    python get_google_token.py
"""

import os
import json
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

# Scopes requeridos
SCOPES = [
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/tasks',
]

def get_refresh_token():
    """Obtiene el refresh token a través del flujo OAuth 2.0"""
    
    creds = None
    
    # El archivo token.json almacena los tokens de acceso y refresh del usuario
    # Se crea automáticamente cuando el flujo de autorización se completa por primera vez
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    
    # Si no hay credenciales válidas disponibles, permite que el usuario inicie sesión
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("Refrescando token expirado...")
            creds.refresh(Request())
        else:
            if not os.path.exists('credentials.json'):
                print("\n❌ ERROR: No se encontró el archivo 'credentials.json'")
                print("\nPor favor, descarga las credenciales OAuth 2.0 desde:")
                print("https://console.cloud.google.com/apis/credentials")
                print("\nY guárdalas como 'credentials.json' en la carpeta backend/")
                return None
            
            print("\n🔐 Iniciando flujo de autorización OAuth 2.0...\n")
            print("Se abrirá una ventana del navegador.")
            print("Por favor, inicia sesión con tu cuenta de Google y acepta los permisos.\n")
            
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', 
                SCOPES
            )
            creds = flow.run_local_server(port=0)
        
        # Guarda las credenciales para la próxima ejecución
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
    
    return creds

def display_credentials(creds):
    """Muestra las credenciales de forma legible"""
    
    print("\n" + "="*70)
    print("✅ AUTORIZACIÓN EXITOSA")
    print("="*70 + "\n")
    
    print("📋 Copia estos valores en tu archivo .env:\n")
    
    # Leer client_id y client_secret desde credentials.json
    with open('credentials.json', 'r') as f:
        credentials_data = json.load(f)
        if 'installed' in credentials_data:
            client_info = credentials_data['installed']
        elif 'web' in credentials_data:
            client_info = credentials_data['web']
        else:
            print("❌ Error: No se pudo leer credentials.json")
            return
    
    print(f"GOOGLE_CLIENT_ID={client_info['client_id']}")
    print(f"GOOGLE_CLIENT_SECRET={client_info['client_secret']}")
    print(f"GOOGLE_REFRESH_TOKEN={creds.refresh_token}")
    print()
    
    print("="*70)
    print("\n💡 NOTA IMPORTANTE:")
    print("   - Guarda estos valores en el archivo backend/.env")
    print("   - NUNCA compartas estas credenciales públicamente")
    print("   - El refresh token no expira, guárdalo de forma segura")
    print("\n" + "="*70 + "\n")

def main():
    """Función principal"""
    print("\n" + "="*70)
    print("Google API - Generador de Refresh Token para AxIA")
    print("="*70 + "\n")
    
    creds = get_refresh_token()
    
    if creds and creds.refresh_token:
        display_credentials(creds)
    elif creds:
        print("\n⚠️  ADVERTENCIA: No se pudo obtener el refresh token.")
        print("    Elimina 'token.json' y ejecuta este script nuevamente.")
    else:
        print("\n❌ Error al obtener las credenciales.")
        print("    Verifica que 'credentials.json' esté presente y sea válido.")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Proceso cancelado por el usuario.")
    except Exception as e:
        print(f"\n\n❌ Error inesperado: {str(e)}")
        print("\nSi el problema persiste, verifica:")
        print("1. Que 'credentials.json' esté en la carpeta backend/")
        print("2. Que las APIs estén habilitadas en Google Cloud Console")
        print("3. Que tu cuenta de Google tenga acceso (usuario de prueba)")
