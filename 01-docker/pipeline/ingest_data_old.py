# --- Block 1: Imports ---
import pandas as pd
from sqlalchemy import create_engine
from tqdm.auto import tqdm  # progress bar for loops

# --- Block 2: Column type definitions ---
dtype = {
    "VendorID": "Int64",
    "passenger_count": "Int64",
    "trip_distance": "float64",
    "RatecodeID": "Int64",
    "store_and_fwd_flag": "string",
    "PULocationID": "Int64",
    "DOLocationID": "Int64",
    "payment_type": "Int64",
    "fare_amount": "float64",
    "extra": "float64",
    "mta_tax": "float64",
    "tip_amount": "float64",
    "tolls_amount": "float64",
    "improvement_surcharge": "float64",
    "total_amount": "float64",
    "congestion_surcharge": "float64"
}

# Columns to parse as datetime instead of plain text
parse_dates = [
    "tpep_pickup_datetime",
    "tpep_dropoff_datetime"
]

def run():
    # --- Block 3: Connection parameters ---
    pg_user = 'root'
    pg_pass = 'root'
    pg_host = 'localhost'
    pg_port = '5432'
    pg_db = 'ny_taxi'

    # --- Block 4: Ingestion parameters ---
    year = 2021
    month = 1
    chunksize = 100000      # number of rows per chunk
    target_table = 'yellow_taxi_data'

    # --- Block 5: Build the CSV URL ---
    prefix = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/'
    url = f'{prefix}yellow_tripdata_{year}-{month:02d}.csv.gz'  # month:02d ensures 2 digits (01, 02...)

    # --- Block 6: Create database connection ---
    # SQLAlchemy engine acts as a bridge between pandas and PostgreSQL
    engine = create_engine(f'postgresql+psycopg://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}')

    # --- Block 7: Create CSV iterator ---
    # Instead of loading the full file into memory, reads it in chunks of 100000 rows
    df_iter = pd.read_csv(
        url,
        dtype=dtype,
        parse_dates=parse_dates,
        iterator=True,
        chunksize=chunksize
    )

    # --- Block 8: Ingest data in chunks ---
    first = True

    for df_chunk in tqdm(df_iter):
        if first:
            # On the first chunk, create the table schema (no data inserted yet)
            df_chunk.head(n=0).to_sql(name=target_table, con=engine, if_exists='replace')
            first = False
        # Append the chunk data to the table
        df_chunk.to_sql(name=target_table, con=engine, if_exists='append')
        print("Inserted:", len(df_chunk))

# Only runs if this file is executed directly (not imported as a module)
if __name__ == '__main__':
    run()
