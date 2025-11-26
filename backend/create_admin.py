import asyncio
from sqlalchemy import select
from database import async_session
from models import User
from security import hash_password


async def create_admin():
    print("Creación del primer usuario (admin)\n")
    username = input("Username (ej: admin): ").strip() or "admin"
    email = input("Email: ").strip() or "admin@axia.com"
    password = input("Password (deja vacío para usar 'admin123'): ").strip() or "admin123"
    full_name = input("Nombre completo (opcional): ").strip() or "Administrador"

    async with async_session() as db:
        # Verificar si el usuario ya existe
        result = await db.execute(select(User).where(User.username == username))
        if result.scalar_one_or_none():
            print(f"Error: El usuario '{username}' ya existe.")
            return

        # Crear usuario
        hashed = hash_password(password)
        admin = User(
            username=username,
            email=email,
            full_name=full_name,
            hashed_password=hashed,
            is_active=True
        )
        db.add(admin)
        await db.commit()
        print(f"\nUsuario '{username}' creado exitosamente!")
        print(f"   Email: {email}")
        print(f"   Contraseña: {password if password != 'admin123' else 'admin123 (por defecto)'}")
        print("\nYa puedes usar este usuario para hacer login en /token")


if __name__ == "__main__":
    asyncio.run(create_admin())