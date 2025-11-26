import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is required")

# Convertir URL si es necesario
if DATABASE_URL.startswith("postgresql://"):
    async_database_url = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
else:
    async_database_url = DATABASE_URL

# MOTOR CORRECTO: con pool normal (NO NullPool)
engine = create_async_engine(
    async_database_url,
    echo=False,
    future=True,
    pool_pre_ping=True,
    pool_size=10,           # Ahora SÍ permitido
    max_overflow=20,        # Ahora SÍ permitido
    pool_timeout=30,
    # poolclass=NullPool   ← ¡ELIMINA ESTA LÍNEA!
)

# Session factory
async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

Base = declarative_base()

# Dependency
async def get_db():
    async with async_session() as session:
        yield session

# Inicializar tablas
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)