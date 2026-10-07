import sqlite3
import pandas as pd
import glob
import os

def create_sqlite_db(db_name="olist.db", data_folder="data"):
    # Establish connection to the SQLite database (creates the file if it doesn't exist)
    conn = sqlite3.connect(db_name)
    
    # Locate all CSV files inside the specified data directory
    csv_files = glob.glob(os.path.join(data_folder, "*.csv"))
    
    if not csv_files:
        print(f"No CSV files found in directory: '{data_folder}'")
        return

    print("Starting database build...")

    for file_path in csv_files:
        # Extract the file name without extension to use as the SQL table name
        table_name = os.path.splitext(os.path.basename(file_path))[0]
        
        # Load CSV into a Pandas DataFrame
        df = pd.read_csv(file_path)
        
        # Write DataFrame to SQLite database table
        df.to_sql(table_name, conn, if_exists="replace", index=False)
        print(f"Successfully loaded '{table_name}' table ({len(df)} records).")

    conn.close()
    print(f"\nDatabase '{db_name}' built successfully!")

if __name__ == "__main__":
    create_sqlite_db()
    