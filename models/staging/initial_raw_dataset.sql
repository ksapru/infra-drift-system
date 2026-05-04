SELECT
  CASE 
    -- 13 digits = Milliseconds
    WHEN LENGTH(CAST(time AS STRING)) = 13 THEN SAFE.TIMESTAMP_MILLIS(CAST(time AS INT64))
    -- 10 digits = Seconds
    WHEN LENGTH(CAST(time AS STRING)) = 10 THEN SAFE.TIMESTAMP_SECONDS(CAST(time AS INT64))
    -- 16 digits = Microseconds
    WHEN LENGTH(CAST(time AS STRING)) = 16 THEN SAFE.TIMESTAMP_MICROS(CAST(time AS INT64))
  ELSE NULL
  END as new_ts,
  1 as unique_machines,
  resource_request.cpus AS avg_cpu,
  resource_request.memory AS avg_memory,
  machine_id
FROM {{ source('ads_raw', 'ads_raw_cluster_m5') }}
WHERE resource_request.cpus IS NOT NULL
  AND resource_request.memory IS NOT NULL
  AND machine_id IS NOT NULL
  -- Only allow the row if our CASE statement actually produced a timestamp
  AND (
    LENGTH(CAST(time AS STRING)) IN (10, 13, 16)
  )