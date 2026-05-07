SELECT
  TIMESTAMP_TRUNC(new_ts, MINUTE) AS new_ts,
  machine_id,
  AVG(avg_cpu) as avg_cpu,
  AVG(avg_memory) as avg_memory,
  1 as unique_machines
FROM {{ ref('initial_raw_dataset') }}
WHERE new_ts IS NOT NULL
GROUP BY 1, 2