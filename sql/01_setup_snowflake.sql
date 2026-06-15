-- ============================================================
-- 01_setup_snowflake.sql
-- Project: Event Data Platform
-- Purpose: Create database, schemas, warehouse, table, stage,
--          and file format for raw event loading.
-- ============================================================

-- Use a warehouse for compute.
-- XSMALL is enough for this portfolio project.
CREATE WAREHOUSE IF NOT EXISTS EVENT_PLATFORM_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE EVENT_PLATFORM_WH;

-- Create project database.
CREATE DATABASE IF NOT EXISTS EVENT_PLATFORM;

USE DATABASE EVENT_PLATFORM;

-- Create schemas for layered architecture.
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS BRONZE;
CREATE SCHEMA IF NOT EXISTS SILVER;
CREATE SCHEMA IF NOT EXISTS GOLD;

-- Use RAW schema for the landing layer.
USE SCHEMA RAW;

-- File format for JSONL / NDJSON files.
-- Our Python script created one JSON object per line.
CREATE OR REPLACE FILE FORMAT JSONL_FORMAT
  TYPE = JSON
  STRIP_OUTER_ARRAY = FALSE;

-- Internal Snowflake stage.
-- This is where we upload local files before loading them.
CREATE OR REPLACE STAGE RAW_EVENTS_STAGE
  FILE_FORMAT = JSONL_FORMAT;

-- Raw table.
-- We intentionally store the original event as VARIANT.
-- This keeps the raw layer close to the source data.
CREATE OR REPLACE TABLE RAW_EVENTS (
  RAW_EVENT VARIANT,
  SOURCE_FILENAME STRING,
  LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);