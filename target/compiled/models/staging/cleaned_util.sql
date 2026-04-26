SELECT
  TIMESTAMP_TRUNC(ts, MINUTE) AS new_ts,
  machine_id,
  cpu,
  memory,
  priority
FROM `krish-dev-data`.`ads_dev`.`initial_raw_dataset`
WHERE ts IS NOT NULL