from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator


PROJECT_ROOT = Path("/Users/urielzaed/Snowflake Certificate/de-snowflake-event-platform")
PYTHON_BIN = PROJECT_ROOT / ".venv" / "bin" / "python"
GENERATE_SCRIPT = PROJECT_ROOT / "scripts" / "generate_events.py"
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"


default_args = {
    "owner": "uriel",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}


with DAG(
    dag_id="event_platform_ingestion_pipeline",
    description="Generate event data, upload it to Snowflake stage, and load it into RAW_EVENTS.",
    start_date=datetime(2026, 6, 1),
    schedule="30 7 * * *",
    catchup=False,
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=30),
    tags=["snowflake", "ingestion", "data-engineering"],
) as dag:

    generate_events_file = BashOperator(
        task_id="generate_events_file",
        bash_command=(
            f"'{PYTHON_BIN}' '{GENERATE_SCRIPT}' "
            "--date '{{ ds }}' "
            "--num-events 1000 "
            "--bad-row-rate 0.02 "
            f"--output-dir '{RAW_DATA_DIR}'"
        ),
        execution_timeout=timedelta(minutes=5),
    )

    upload_file_to_snowflake_stage = BashOperator(
        task_id="upload_file_to_snowflake_stage",
        bash_command=(
            "snowsql -c event_platform -q "
            "\""
            "USE WAREHOUSE EVENT_PLATFORM_WH; "
            "USE DATABASE EVENT_PLATFORM; "
            "USE SCHEMA RAW; "
            f"PUT 'file://{RAW_DATA_DIR}/events_{{{{ ds }}}}.jsonl' "
            "@RAW_EVENTS_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
            "\""
        ),
        execution_timeout=timedelta(minutes=10),
    )

    copy_into_raw_events = BashOperator(
        task_id="copy_into_raw_events",
        bash_command=(
            "snowsql -c event_platform -q "
            "\""
            "USE WAREHOUSE EVENT_PLATFORM_WH; "
            "USE DATABASE EVENT_PLATFORM; "
            "USE SCHEMA RAW; "
            "COPY INTO RAW_EVENTS (RAW_EVENT, SOURCE_FILENAME) "
            "FROM ("
            "SELECT "
            "\\$1 AS RAW_EVENT, "
            "METADATA\\$FILENAME AS SOURCE_FILENAME "
            "FROM @RAW_EVENTS_STAGE"
            ") "
            "FILE_FORMAT = (FORMAT_NAME = JSONL_FORMAT) "
            "PATTERN = '.*events_{{ ds }}.*' "
            "ON_ERROR = 'ABORT_STATEMENT';"
            "\""
        ),
        execution_timeout=timedelta(minutes=10),
    )

    trigger_dbt_pipeline = TriggerDagRunOperator(
        task_id="trigger_dbt_pipeline",
        trigger_dag_id="event_platform_dbt_pipeline",
    )

    (
        generate_events_file
        >> upload_file_to_snowflake_stage
        >> copy_into_raw_events
        >> trigger_dbt_pipeline
    )
