SELECT 
    new_ts,
    SUM(unique_machines) as unique_machines,
    AVG(avg_cpu) as avg_cpu,
    AVG(avg_memory) as avg_memory
FROM {{ ref('cleaned_util') }}
GROUP BY 1
