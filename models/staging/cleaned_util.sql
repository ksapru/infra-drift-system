SELECT
  TIMESTAMP_TRUNC(new_ts, MINUTE) AS new_ts,
  machine_id,
  avg_cpu,
  avg_memory
FROM {{ ref('initial_raw_dataset') }}
WHERE new_ts IS NOT NULL