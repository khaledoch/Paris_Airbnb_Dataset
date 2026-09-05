"""
load_csvs.py

One command to go from "zip of CSVs" -> "queryable Postgres database".

What it does:
  1. Unzips your CSV archive into ./data/raw
  2. Connects to your LOCAL Postgres server (creds from .env)
  3. Creates the target database if it doesn't already exist
  4. For every CSV found (including in subfolders), infers a clean table
     name and column names, and loads it into Postgres
  5. Prints a summary (table name, row count, columns) so you can see
     exactly what landed where

Usage:
    python load_csvs.py path/to/your.zip

Requires a .env file next to this script (copy .env.example -> .env and
fill in your real local Postgres credentials).
"""

import os
import re
import sys
import zipfile
from pathlib import Path

import chardet
import pandas as pd
import psycopg2
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()

PGHOST = os.getenv("PGHOST", "localhost")
PGPORT = os.getenv("PGPORT", "5432")
PGDATABASE = os.getenv("PGDATABASE", "csv_project")
PGUSER = os.getenv("PGUSER", "postgres")
PGPASSWORD = os.getenv("PGPASSWORD", "")

RAW_DIR = Path("data/raw")


def clean_name(name: str) -> str:
    """Turn 'My Weird Column Name!!' into 'my_weird_column_name'."""
    name = name.strip().lower()
    name = re.sub(r"[^\w]+", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    if not name:
        name = "col"
    if name[0].isdigit():
        name = f"c_{name}"
    return name


def detect_encoding(path: Path) -> str:
    with open(path, "rb") as f:
        raw = f.read(200_000)  # sample is enough
    guess = chardet.detect(raw)
    return guess["encoding"] or "utf-8"


def ensure_database_exists():
    """Connect to the default 'postgres' db and create our target db if missing."""
    conn = psycopg2.connect(
        host=PGHOST, port=PGPORT, dbname="postgres",
        user=PGUSER, password=PGPASSWORD,
    )
    conn.autocommit = True
    with conn.cursor() as cur:
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (PGDATABASE,))
        exists = cur.fetchone()
        if not exists:
            print(f"Database '{PGDATABASE}' not found — creating it.")
            cur.execute(f'CREATE DATABASE "{PGDATABASE}"')
        else:
            print(f"Database '{PGDATABASE}' already exists — using it.")
    conn.close()


def unzip_csvs(zip_path: Path) -> list[Path]:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path, "r") as z:
        z.extractall(RAW_DIR)
    csv_files = sorted(RAW_DIR.rglob("*.csv"))
    if not csv_files:
        sys.exit(f"No CSV files found inside {zip_path}. Check the zip contents.")
    return csv_files


def load_csv_to_postgres(csv_path: Path, engine):
    table_name = clean_name(csv_path.stem)
    encoding = detect_encoding(csv_path)

    try:
        df = pd.read_csv(csv_path, encoding=encoding, low_memory=False)
    except Exception as e:
        print(f"  ! Skipped {csv_path.name}: could not parse ({e})")
        return

    df.columns = [clean_name(c) for c in df.columns]

    # de-duplicate any columns that collide after cleaning
    seen = {}
    new_cols = []
    for c in df.columns:
        if c in seen:
            seen[c] += 1
            new_cols.append(f"{c}_{seen[c]}")
        else:
            seen[c] = 0
            new_cols.append(c)
    df.columns = new_cols

    df.to_sql(table_name, engine, if_exists="replace", index=False, method="multi", chunksize=5000)

    print(f"  ✓ {csv_path.name}  ->  table \"{table_name}\"  "
          f"({len(df):,} rows, {len(df.columns)} columns)")


def main():
    if len(sys.argv) != 2:
        sys.exit("Usage: python load_csvs.py path/to/your.zip")

    zip_path = Path(sys.argv[1])
    if not zip_path.exists():
        sys.exit(f"File not found: {zip_path}")

    print("Step 1/3: Unzipping CSVs...")
    csv_files = unzip_csvs(zip_path)
    print(f"  Found {len(csv_files)} CSV file(s).")

    print("\nStep 2/3: Making sure the database exists...")
    ensure_database_exists()

    print("\nStep 3/3: Loading tables...")
    conn_str = f"postgresql+psycopg2://{PGUSER}:{PGPASSWORD}@{PGHOST}:{PGPORT}/{PGDATABASE}"
    engine = create_engine(conn_str)

    for csv_path in csv_files:
        load_csv_to_postgres(csv_path, engine)

    print("\nDone. Open this folder in VS Code, install the recommended")
    print("SQLTools extensions if prompted, and start querying — the")
    print("connection is already pre-configured in .vscode/settings.json.")


if __name__ == "__main__":
    main()
