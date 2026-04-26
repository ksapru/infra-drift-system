SELECT 
    new_ts,
    COUNT(DISTINCT machine_id) as unique_machines,
    AVG(CPU) as avg_cpu,
    AVG(memory) as avg_memory
FROM `krish-dev-data`.`ads_dev`.`cleaned_util`
GROUP BY 1