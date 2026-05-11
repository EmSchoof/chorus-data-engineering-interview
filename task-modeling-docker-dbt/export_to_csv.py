#!/usr/bin/env python3
"""
Export dbt models to CSV files.
Connects to PostgreSQL and exports dimension and fact tables (excluding staging, FHIR, and seeds by default).
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List, Optional

import psycopg2
import pandas as pd
from psycopg2 import sql


class DBTExporter:
    """Export dbt models from PostgreSQL to CSV files."""

    def __init__(
        self,
        host: str = "localhost",
        port: int = 5432,
        user: str = "user",
        password: Optional[str] = None,
        database: str = "postgres",
        schema: str = "public",
        output_dir: str = "exports",
    ):
        """Initialize database connection parameters."""
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.database = database
        self.schema = schema
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.conn = None

    def connect(self) -> None:
        """Establish database connection."""
        try:
            self.conn = psycopg2.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=self.database,
            )
            print(f"✓ Connected to {self.user}@{self.host}:{self.port}/{self.database}")
        except psycopg2.Error as e:
            print(f"✗ Connection failed: {e}")
            sys.exit(1)

    def disconnect(self) -> None:
        """Close database connection."""
        if self.conn:
            self.conn.close()
            print("✓ Disconnected from database")

    def get_tables(self) -> List[str]:
        """Get list of tables in the schema."""
        query = """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = %s
            ORDER BY table_name
        """
        df = pd.read_sql(query, self.conn, params=(self.schema,))
        return df["table_name"].tolist()

    def export_table(self, table_name: str) -> bool:
        """Export a single table to CSV."""
        try:
            query = sql.SQL("SELECT * FROM {}.{}").format(
                sql.Identifier(self.schema), sql.Identifier(table_name)
            )
            df = pd.read_sql(query.as_string(self.conn), self.conn)

            output_file = self.output_dir / f"{table_name}.csv"
            df.to_csv(output_file, index=False)

            print(f"  ✓ {table_name}: {len(df)} rows → {output_file}")
            return True
        except Exception as e:
            print(f"  ✗ {table_name}: {e}")
            return False

    def export_select(self) -> None:
        """Export all tables matching criteria."""
        tables = self.get_tables()

        # Exclude FHIR tables and staging models by default
        excluded_by_default = {
            "MedicationRequest", "Patient", "Practitioner", "Observation", "Encounter",  # FHIR tables
        }
        tables = [t for t in tables if t not in excluded_by_default]
        
        # Exclude staging models
        tables = [t for t in tables if not t.startswith("stg_")]

        # Exclude seed files
        excluded_seeds = {"people", "tasks", "task_assignment", "task_occurrence_status"}
        tables = [t for t in tables if t not in excluded_seeds]

        print(f"\nExporting {len(tables)} table(s) to {self.output_dir}/")
        successful = sum(self.export_table(t) for t in tables)
        print(f"\n✓ Successfully exported {successful}/{len(tables)} tables")

    def export_models(self, models: List[str]) -> None:
        """Export specific models by name."""
        print(f"\nExporting {len(models)} model(s) to {self.output_dir}/")
        successful = sum(self.export_table(m) for m in models)
        print(f"\n✓ Successfully exported {successful}/{len(models)} models")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Export dbt models to CSV files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Export dim and fct models only (default, excludes stg_, FHIR, seeds)
  python export_to_csv.py

  # Export specific models
  python export_to_csv.py --models fct_task_occurrences dim_tasks
        """,
    )

    parser.add_argument(
        "--host",
        default="localhost",
        help="Database host (default: localhost)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=5432,
        help="Database port (default: 5432)",
    )
    parser.add_argument(
        "--user",
        default="user",
        help="Database user (default: user)",
    )
    parser.add_argument(
        "--password",
        help="Database password (optional)",
    )
    parser.add_argument(
        "--database",
        default="postgres",
        help="Database name (default: postgres)",
    )
    parser.add_argument(
        "--schema",
        default="public",
        help="Schema name (default: public)",
    )
    parser.add_argument(
        "--output-dir",
        default="exports",
        help="Output directory for CSV files (default: exports)",
    )
    parser.add_argument(
        "--models",
        nargs="+",
        help="Export specific models by name (e.g., fct_task_occurrences dim_tasks)",
    )
    args = parser.parse_args()

    exporter = DBTExporter(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
        schema=args.schema,
        output_dir=args.output_dir,
    )

    exporter.connect()
    try:
        if args.models:
            exporter.export_models(args.models)
        else:
            exporter.export_select()
    finally:
        exporter.disconnect()


if __name__ == "__main__":
    main()
