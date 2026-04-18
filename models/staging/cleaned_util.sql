SELECT 
    TIMESTAMP_TRUNC(ts, HOUR) as new_ts, 
    machine_id, 
    cpu, 
    memory, 
    priority
FROM `krish-dev-data.ads_raw.instance_events`
LIMIT 10