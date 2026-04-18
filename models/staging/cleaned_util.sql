SELECT TIMESTAMP_TRUNC(ts, HOUR) as new_ts 
FROM `krish-dev-data.ads_raw.instance_events` 
LIMIT 10