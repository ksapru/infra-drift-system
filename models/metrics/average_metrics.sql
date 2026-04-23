CREATE OR REPLACE TABLE `krish-dev-data.ads_raw.average_metrics` AS 
SELECT 
    new_ts,
    COUNT(DISTINCT machine_id) as unique_machines,
    AVG(CPU) as avg_cpu,
    AVG(memory) as avg_memory,
    priority
FROM `krish-dev-data.ads_raw.cleaned_util`
GROUP BY new_ts,priority
ORDER BY new_ts ASC
