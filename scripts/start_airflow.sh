#!/bin/bash

set -e

PROJECT_ROOT="/Users/urielzaed/Snowflake Certificate/de-snowflake-event-platform"

cd "$PROJECT_ROOT"

source .airflow-venv/bin/activate

export AIRFLOW_HOME="$PROJECT_ROOT/.airflow"
export AIRFLOW__CORE__DAGS_FOLDER="$PROJECT_ROOT/dags"
export AIRFLOW__CORE__LOAD_EXAMPLES=False

airflow standalone