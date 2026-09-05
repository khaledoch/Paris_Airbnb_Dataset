import os
import psycopg2
from dotenv import load_dotenv

load_dotenv(r'C:\Users\LENOVO\Desktop\csv-to-postgres\.env')

conn = psycopg2.connect(
    host=os.getenv('PGHOST', 'localhost'),
    port=os.getenv('PGPORT', '5432'),
    dbname=os.getenv('PGDATABASE', 'csv_project'),
    user=os.getenv('PGUSER', 'postgres'),
    password=os.getenv('PGPASSWORD', '')
)
cur = conn.cursor()

for table in ['listings', 'calendar', 'reviews']:
    cur.execute(
        "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND table_name=%s ORDER BY ordinal_position;",
        (table,)
    )
    print(f'\nTABLE: {table}')
    for row in cur.fetchall():
        print(row[0], '->', row[1])

cur.close()
conn.close()
