from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.standard.operators.bash import BashOperator


PROJECT_ROOT = "/Users/urielzaed/Snowflake Certificate/de-snowflake-event-platform"
DBT_PROJECT_DIR = f"{PROJECT_ROOT}/event_platform_dbt"
DBT_BIN = f"{PROJECT_ROOT}/.venv/bin/dbt"


with DAG(
    dag_id="event_platform_dbt_pipeline",
    description="Run dbt transformations and tests for the Snowflake event platform.",
    start_date=datetime(2026, 6, 1),
    schedule=None,
    catchup=False,
    tags=["snowflake", "dbt", "data-engineering"],
) as dag:

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd '{DBT_PROJECT_DIR}' && '{DBT_BIN}' run",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd '{DBT_PROJECT_DIR}' && '{DBT_BIN}' test",
    )

    dbt_run >> dbt_test