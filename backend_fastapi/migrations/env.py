from alembic import context

from app.database import engine

with engine().connect() as connection:
    context.configure(connection=connection)
    with context.begin_transaction():
        # Protect migration adoption/creation from concurrent deployments.
        connection.exec_driver_sql("SELECT pg_advisory_xact_lock(178231114)")
        context.run_migrations()
