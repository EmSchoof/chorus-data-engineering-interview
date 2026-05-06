#!/usr/bin/env python3
"""
Export dbt model results to CSV files.

Usage:
    python export_to_csv.py                    # Export all models
    python export_to_csv.py --models staging   # Export only staging
    python export_to_csv.py --output ./data    # Custom output directory
"""

import subprocess
import psycopg2
import os
import sys
import argparse
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from src/.env
load_dotenv("src/.env")

# Database configuration
DB_CONFIG = {
    "dbname": os.getenv("POSTGRES_DB", "postgres"),
    "user": os.getenv("POSTGRES_USER", "user"),
    "password": os.getenv("POSTGRES_PASSWORD", "password"),
    "host": os.getenv("POSTGRES_HOST", "localhost"),
    "port": os.getenv("POSTGRES_PORT", "5432")
}

# Models to export categorized by layer
MODELS = {
    "01_beginner": [
        "dim_all_active_patients",
        "dim_encounters_per_specific_patient",
        "dim_observations_per_specific_patient"
    ],
    "02_intermediate": [
        "dim_patient_multi_practitioners",
        "dim_practictioner_no_prescriptions",
        "dim_recent_patient_encounters",
        "dim_top_3_prescriptions"
    ],
    "03_advanced": [
        "dim_avg_encounter_per_patient",
        "dim_patient_prescription_wo_encounter",
        "dim_patient_retention_per_cohort"
    ]
}


def run_dbt():
    """Run dbt to materialize all models."""
    print("🔄 Running dbt...")
    try:
        result = subprocess.run(
            ["dbt", "run"],
            cwd="dbt",
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"❌ dbt run failed:\n{result.stderr}")
            sys.exit(1)
        print("✅ dbt run completed")
    except FileNotFoundError:
        print("❌ dbt not found. Install with: pip install dbt-postgres")
        sys.exit(1)


def export_models_to_csv(output_dir, model_layers=None):
    """Export dbt models to CSV files."""
    output_dir = Path(output_dir)
    output_dir.mkdir(exist_ok=True, parents=True)
    
    # Determine which models to export
    if model_layers:
        models_to_export = {}
        for layer in model_layers:
            if layer in MODELS:
                models_to_export[layer] = MODELS[layer]
            else:
                print(f"⚠️  Layer '{layer}' not found. Available: {', '.join(MODELS.keys())}")
    else:
        models_to_export = MODELS
    
    # Connect to database
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except psycopg2.OperationalError as e:
        print(f"❌ Database connection failed: {e}")
        print(f"   Check credentials in src/.env or ~/.dbt/profiles.yml")
        sys.exit(1)
    
    total_models = sum(len(models) for models in models_to_export.values())
    exported_count = 0
    failed_models = []
    
    print(f"\n📁 Exporting {total_models} models to: {output_dir.absolute()}")
    
    # Export each model
    for layer, models in models_to_export.items():
        layer_dir = output_dir / layer
        layer_dir.mkdir(exist_ok=True)
        
        for model in models:
            output_file = layer_dir / f"{model}.csv"
            try:
                # Use COPY with subquery - works for both tables and views
                with open(output_file, 'w') as f:
                    cursor.copy_expert(f"COPY (SELECT * FROM {model}) TO STDOUT WITH CSV HEADER", f)
                
                # Get row count
                cursor.execute(f"SELECT COUNT(*) FROM {model}")
                row_count = cursor.fetchone()[0]
                
                print(f"  ✓ {model:50} → {output_file.name:40} ({row_count:,} rows)")
                exported_count += 1
            except psycopg2.Error as e:
                print(f"  ✗ {model:50} → ERROR: {str(e)[:60]}")
                failed_models.append((model, str(e)))
    
    cursor.close()
    conn.close()
    
    # Summary
    print(f"\n{'='*100}")
    print(f"📊 Export Summary: {exported_count}/{total_models} successful")
    
    if failed_models:
        print(f"\n⚠️  Failed models ({len(failed_models)}):")
        for model, error in failed_models:
            print(f"   - {model}: {error[:80]}")
    
    if exported_count == total_models:
        print(f"✅ All models exported to: {output_dir.absolute()}")
        return 0
    else:
        return 1


def main():
    parser = argparse.ArgumentParser(
        description="Export dbt model results to CSV files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python export_to_csv.py                         # Export all models
  python export_to_csv.py --models staging        # Staging only
  python export_to_csv.py --models staging 01_beginner  # Multiple layers
  python export_to_csv.py --output ./my_data      # Custom output directory
        """
    )
    
    parser.add_argument(
        "--output",
        default="./csv_output",
        help="Output directory for CSV files (default: ./csv_output)"
    )
    
    parser.add_argument(
        "--models",
        nargs="+",
        choices=list(MODELS.keys()),
        help="Export specific model layers (default: all)"
    )
    
    parser.add_argument(
        "--no-dbt",
        action="store_true",
        help="Skip running dbt (assumes models already materialized)"
    )
    
    args = parser.parse_args()
    
    # Run dbt unless --no-dbt flag is set
    if not args.no_dbt:
        run_dbt()
    
    # Export to CSV
    exit_code = export_models_to_csv(args.output, args.models)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
