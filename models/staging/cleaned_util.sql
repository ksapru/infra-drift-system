CREATE OR REPLACE TABLE `krish-dev-data.ads_raw.cleaned_util` AS
SELECT
  TIMESTAMP_TRUNC(ts, MINUTE) AS new_ts,
  machine_id,
  cpu,
  memory,
  priority
FROM `krish-dev-data.ads_raw.instance_events`
WHERE ts IS NOT NULL;