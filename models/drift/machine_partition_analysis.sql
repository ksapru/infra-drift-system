/*
    MACHINE PARTITION ANALYSIS
    Goal: Identify which specific "inputs" (machines) are driving forecast error.
*/

WITH machine_errors AS (
    SELECT 
        machine_id,
        new_ts,
        avg_cpu,
        avg_memory,
        ABS(cpu_err) as abs_cpu_err,
        ABS(mem_err) as abs_mem_err
    FROM {{ ref('error_metrics') }}
),

machine_aggregates AS (
    SELECT
        machine_id,
        COUNT(*) as sample_count,
        AVG(abs_cpu_err) as mean_abs_cpu_err,
        AVG(abs_mem_err) as mean_abs_mem_err,
        STDDEV(abs_cpu_err) as cpu_volatility
    FROM machine_errors
    GROUP BY 1
),

partition_ranking AS (
    SELECT
        *,
        CASE 
            WHEN mean_abs_cpu_err > 50 OR cpu_volatility > 20 THEN 'Unreliable Input (Critical)'
            WHEN mean_abs_cpu_err > 10 OR cpu_volatility > 5 THEN 'Variable Input (Minor)'
            ELSE 'Stable Input (Healthy)'
        END as input_reliability_tier
    FROM machine_aggregates
)

SELECT * FROM partition_ranking
ORDER BY mean_abs_cpu_err DESC
