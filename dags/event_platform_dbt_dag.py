from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.providers.standard.operators.bash import BashOperator


PROJECT_ROOT = Path("/Users/urielzaed/Snowflake Certificate/de-snowflake-event-platform")
DBT_PROJECT_DIR = PROJECT_ROOT / "event_platform_dbt"
DBT_BIN = PROJECT_ROOT / ".venv" / "bin" / "dbt"


default_args = {
    "owner": "uriel",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}


def dbt_command(command: str) -> str:
    return f"cd '{DBT_PROJECT_DIR}' && '{DBT_BIN}' {command}"


with DAG(
    dag_id="event_platform_dbt_pipeline",
    description="Run dbt seed, snapshots, transformations, and tests for the Snowflake event platform.",
    start_date=datetime(2026, 6, 1),
    schedule="0 8 * * *",
    catchup=False,
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=45),
    tags=["snowflake", "dbt", "airflow", "data-engineering"],
) as dag:

    dbt_debug = BashOperator(
        task_id="dbt_debug",
        bash_command=dbt_command("debug"),
        execution_timeout=timedelta(minutes=5),
    )

    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=dbt_command("seed --full-refresh"),
        execution_timeout=timedelta(minutes=10),
    )

    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot",
        bash_command=dbt_command("snapshot"),
        execution_timeout=timedelta(minutes=10),
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=dbt_command("run"),
        execution_timeout=timedelta(minutes=20),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=dbt_command("test"),
        execution_timeout=timedelta(minutes=15),
    )

    dbt_debug >> dbt_seed >> dbt_snapshot >> dbt_run >> dbt_test