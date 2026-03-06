import click
import pandas as pd
from pathlib import Path
from tqdm.auto import tqdm
import pyarrow.parquet as pq
from sqlalchemy import create_engine


@click.command()
@click.option('--pg-user', default='root', help='PostgreSQL user')
@click.option('--pg-pass', default='root', help='PostgreSQL password')
@click.option('--pg-host', default='localhost', help='PostgreSQL host')
@click.option('--pg-port', default=5432, type=int, help='PostgreSQL port')
@click.option('--pg-db', default='ny_taxi', help='PostgreSQL database name')
@click.option('--green-taxi-file', required=True, help='Path to green taxi parquet file')
@click.option('--taxi-zone-file', required=True, help='Path to taxi zone lookup CSV file')
@click.option('--green-taxi-table', default='green_taxi_data', help='Target table name for green taxi data')
@click.option('--taxi-zone-table', default='taxizonelookup_data', help='Target table name for taxi zone lookup data')
def run(pg_user, pg_pass, pg_host, pg_port, pg_db, green_taxi_file, taxi_zone_file,
        green_taxi_table, taxi_zone_table):
    """Ingest NYC green taxi data and taxi zone lookup data into PostgreSQL database."""
    engine = create_engine(f'postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}')

    ingest_green_taxi_data(engine, green_taxi_file, green_taxi_table)
    ingest_taxi_zone_data(engine, taxi_zone_file, taxi_zone_table)


def ingest_green_taxi_data(engine, parquet_file_path, target_table):
    """Ingest green taxi parquet data into PostgreSQL."""
    parquet_file_path = Path(parquet_file_path)
    
    if not parquet_file_path.exists():
        raise FileNotFoundError(f"Green taxi file not found: {parquet_file_path}")
    
    print(f"Ingesting green taxi data from {parquet_file_path}")
    
    # Read full dataframe to get total row count for reporting
    greentrip_df = pd.read_parquet(parquet_file_path)
    
    # Use PyArrow's ParquetFile to read in batches
    parquet_file = pq.ParquetFile(parquet_file_path)
    num_row_groups = parquet_file.num_row_groups

    print(f"Total number of row groups: {num_row_groups}")
    print(f"Total rows in dataframe: {len(greentrip_df)}")

    first = True
    total_rows_inserted = 0

    for i in tqdm(range(num_row_groups), desc="Processing row groups"):
        # Read one row group at a time
        row_group = parquet_file.read_row_group(i)
        greentaxi_df_chunk = row_group.to_pandas()

        print(f"Row group {i}: {len(greentaxi_df_chunk)} rows")

        if first:
            greentaxi_df_chunk.head(0).to_sql(
                name=target_table,
                con=engine,
                if_exists='replace',
                index=False
            )
            first = False

        greentaxi_df_chunk.to_sql(
            name=target_table,
            con=engine,
            if_exists='append',
            index=False
        )
        total_rows_inserted += len(greentaxi_df_chunk)

    print(f"\n Successfully inserted {total_rows_inserted} rows into '{target_table}' table")


def ingest_taxi_zone_data(engine, csv_file_path, target_table):
    """Ingest taxi zone lookup CSV data into PostgreSQL."""
    csv_file_path = Path(csv_file_path)
    
    if not csv_file_path.exists():
        raise FileNotFoundError(f"Taxi zone file not found: {csv_file_path}")
    
    print(f"\nIngesting taxi zone lookup data from {csv_file_path}")

    taxizonelookup_df = pd.read_csv(csv_file_path)

    print(f"Total rows to insert: {len(taxizonelookup_df)}")

    taxizonelookup_df.head(0).to_sql(
        name=target_table,
        con=engine,
        if_exists='replace',
        index=False
    )

    taxizonelookup_df.to_sql(
        name=target_table,
        con=engine,
        if_exists='append',
        index=False
    )

    print(f" Successfully inserted {len(taxizonelookup_df)} rows into '{target_table}' table")


if __name__ == '__main__':
    run()
