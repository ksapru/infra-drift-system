CREATE OR REPLACE TABLE ads_raw.instance_events AS
SELECT
  CASE 
    WHEN time BETWEEN 1e12 AND 1e14 THEN TIMESTAMP_MILLIS(time)
    WHEN time BETWEEN 1e9 AND 1e12 THEN TIMESTAMP_MILLIS(time)
  ELSE NULL
  END as ts,
  priority,
  machine_id,
  resource_request.cpus AS cpu,
  resource_request.memory AS memory
FROM ads_raw.ads_raw_cluster_m5
WHERE resource_request.cpus IS NOT NULL
  AND resource_request.memory IS NOT NULL;