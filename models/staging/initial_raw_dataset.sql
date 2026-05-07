/*
    STAGING: INITIAL RAW DATASET (BORG 2019 - NESTED SANITIZATION)
    Fix: Explicitly extracting struct columns (resource_request) in the first CTE.
*/

WITH sanitized AS (
    -- STEP 1: Extract and Sanitize
    SELECT 
      time,
      machine_id,
      resource_request.cpus,
      resource_request.memory
    FROM {{ source('ads_raw', 'ads_raw_cluster_m5') }}
    WHERE resource_request.cpus IS NOT NULL
      AND resource_request.memory IS NOT NULL
      AND machine_id IS NOT NULL
      -- Pre-check: time must be a number and must be reasonably small (< 10 years of micros)
      AND SAFE_CAST(time AS INT64) IS NOT NULL
      AND SAFE_CAST(time AS INT64) < 315360000000000 
),

base_parsed AS (
    SELECT
      SAFE.TIMESTAMP_ADD(
        TIMESTAMP('2019-04-30 23:50:00'), 
        INTERVAL CAST(time AS INT64) MICROSECOND
      ) as new_ts,
      1 as unique_machines,
      cpus AS avg_cpu,
      memory AS avg_memory,
      machine_id
    FROM sanitized
)

SELECT * 
FROM base_parsed
WHERE new_ts >= '2019-04-30' AND new_ts < '2019-06-01'
