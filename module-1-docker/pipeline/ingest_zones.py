# --- Block 1: Imports ---
import pandas as pd
from sqlalchemy import create_engine
import click

# --- Block 2: CLI definition ---
@click.command()
@click.option('--pg-user', default='root', help='PostgreSQL user')
@click.option('--pg-pass', default='root', help='PostgreSQL password')
@click.option('--pg-host', default='localhost', help='PostgreSQL host')
@click.option('--pg-port', default=5432, type=int, help='PostgreSQL port')
@click.option('--pg-db', default='ny_taxi', help='PostgreSQL database name')
@click.option('--target-table', default='zones', help='Target table name')

def run(pg_user, pg_pass, pg_host, pg_port, pg_db, target_table):

    # --- Block 3: Database connection ---
    engine = create_engine(f'postgresql+psycopg://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}')

    # --- Block 4: Download and ingest ---
    # Small file — no need for chunks, load all at once
    url = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv'
    df = pd.read_csv(url)
    df.to_sql(name=target_table, con=engine, if_exists='replace')
    print(f"Done! Inserted {len(df)} rows into '{target_table}'")

# Only runs if this file is executed directly
if __name__ == '__main__':
    run()
