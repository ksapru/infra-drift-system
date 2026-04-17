{{ config(materialized='view') }}

WITH raw_utilization AS (
    SELECT
        resource_id,
        CAST(cpu_usage AS FLOAT64) AS cpu_usage,
        CAST(memory_usage AS FLOAT64) AS memory_usage,
        timestamp,
        provider
    FROM {{ source('raw_data', 'utilization_metrics') }}
),

cleaned_data AS (
    SELECT
        resource_id,
        COALESCE(cpu_usage, 0) AS cpu_usage,
        COALESCE(memory_usage, 0) AS memory_usage,
        timestamp,
        UPPER(provider) AS provider_name
    FROM raw_utilization
    WHERE resource_id IS NOT NULL
)

SELECT * FROM cleaned_data
ORDER BY timestamp DESC
LIMIT 10000