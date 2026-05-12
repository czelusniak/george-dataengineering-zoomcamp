# --- Block 1: Imports ---
import pandas as pd
from sqlalchemy import create_engine

# --- Block 2: Configuration ---
# Base URL where the CSV files are hosted
prefix = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/'

# Column type definitions — tells pandas which type to use for each column
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

# --- Block 3: Exploratory read ---
# Read only 100 rows to inspect the data before ingesting everything
df = pd.read_csv(
    prefix + 'yellow_tripdata_2021-01.csv.gz',
    nrows=100,
    dtype=dtype,
    parse_dates=parse_dates
)
# These lines were useful in Jupyter but do nothing in a .py script without print()
# df.head()
# df.dtypes
# df.shape
# len(df)

# --- Block 4: Database connection ---
# SQLAlchemy engine acts as a bridge between pandas and PostgreSQL
engine = create_engine('postgresql+psycopg://root:root@localhost:5432/ny_taxi')

# Preview the CREATE TABLE SQL that pandas would generate — useful to verify column types
print(pd.io.sql.get_schema(df, name='yellow_taxi_data', con=engine))

# Create the table structure in PostgreSQL without inserting any data yet
df.head(n=0).to_sql(name='yellow_taxi_data', con=engine, if_exists='replace')

# --- Block 5: Ingest data in chunks ---
# Read the full file as an iterator to avoid loading everything into memory at once
df_iter = pd.read_csv(
    prefix + 'yellow_tripdata_2021-01.csv.gz',
    dtype=dtype,
    parse_dates=parse_dates,
    iterator=True,
    chunksize=100000  # process 100000 rows at a time
)

# Insert each chunk into the table, appending to existing data
for df_chunk in df_iter:
    df_chunk.to_sql(name='yellow_taxi_data', con=engine, if_exists='append')
    print("Inserted:", len(df_chunk))
