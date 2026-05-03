SELECT
  CASE 
    WHEN time BETWEEN 1000000000000 AND 32503680000000 THEN SAFE.TIMESTAMP_MILLIS(CAST(time AS INT64))
    WHEN time BETWEEN 1000000000    AND 1000000000000  THEN SAFE.TIMESTAMP_SECONDS(CAST(time AS INT64))
  ELSE NULL
  END as new_ts,
  1 as unique_machines,
  resource_request.cpus AS avg_cpu,
  resource_request.memory AS avg_memory,
  machine_id
FROM {{ source('ads_raw', 'ads_raw_cluster_m5') }}
WHERE resource_request.cpus IS NOT NULL
  AND resource_request.memory IS NOT NULL