WITH drift_accuracy AS (
    SELECT
        *,
        -- Alerts when CPU percentage error deviates from historical baseline. 
        -- Healthy: < 5% increase | Minor: 5-20% increase | Critical: > 20% increase
        CASE
            WHEN mape_cpu_val <= rolling_avg_mape_cpu * 1.05 THEN 'Healthy'
            WHEN mape_cpu_val <= rolling_avg_mape_cpu * 1.20 THEN 'Minor Drift'
            ELSE 'Critical Drift'
        END as cpu_mape_status,

        -- Detects memory percentage error drift. 
        -- Healthy: < 5% increase | Minor: 5-20% increase | Critical: > 20% increase
        CASE
            WHEN mape_mem_val <= rolling_avg_mape_mem * 1.05 THEN 'Healthy'
            WHEN mape_mem_val <= rolling_avg_mape_mem * 1.20 THEN 'Minor Drift'
            ELSE 'Critical Drift'
        END as mem_mape_status,

        -- RMSE penalizes large outliers. Catching this prevents severe application degradation.
        CASE
            WHEN sqrt(mse_cpu) <= rolling_avg_rmse_cpu * 1.05 THEN 'Healthy'
            WHEN sqrt(mse_cpu) <= rolling_avg_rmse_cpu * 1.20 THEN 'Minor Drift'
            ELSE 'Critical Drift'
        END as cpu_rmse_status,

        -- Catching large memory prediction outliers prevents severe performance bottlenecks.
        CASE
            WHEN sqrt(mse_mem) <= rolling_avg_rmse_mem * 1.05 THEN 'Healthy'
            WHEN sqrt(mse_mem) <= rolling_avg_rmse_mem * 1.20 THEN 'Minor Drift'
            ELSE 'Critical Drift'
        END as mem_rmse_status,

        -- Tracks raw CPU absolute error to directly alert on wasted CPU core allocations.
        CASE
            WHEN cpu_err <= rolling_avg_cpu_err * 1.05 THEN 'Healthy'
            WHEN cpu_err <= rolling_avg_cpu_err * 1.20 THEN 'Minor Drift'
            ELSE 'Critical Drift'
        END as cpu_err_status,

        -- Tracks raw memory absolute error to directly measure and alert on wasted memory.
        CASE
            WHEN mem_err <= rolling_avg_mem_err * 1.05 THEN 'Healthy'
            WHEN mem_err <= rolling_avg_mem_err * 1.20 THEN 'Minor Drift'
            ELSE 'Critical Drift'
        END as mem_err_status
    FROM {{ ref('rolling_metrics') }}
    WHERE
        new_ts IS NOT NULL
        AND rolling_avg_rmse_cpu IS NOT NULL
),

drift_count AS (
    SELECT
        new_ts,
        -- Total number of machines checked at this timestamp
        COUNT(*) as total_machines,
        
        -- Count of machines experiencing Critical Drift for each metric
        COUNT(CASE WHEN cpu_mape_status = 'Critical Drift' THEN 1 END) as cpu_mape_drift_count,
        COUNT(CASE WHEN mem_mape_status = 'Critical Drift' THEN 1 END) as mem_mape_drift_count,
        COUNT(CASE WHEN cpu_rmse_status = 'Critical Drift' THEN 1 END) as cpu_rmse_drift_count,
        COUNT(CASE WHEN mem_rmse_status = 'Critical Drift' THEN 1 END) as mem_rmse_drift_count,
        COUNT(CASE WHEN cpu_err_status = 'Critical Drift' THEN 1 END) as cpu_err_drift_count,
        COUNT(CASE WHEN mem_err_status = 'Critical Drift' THEN 1 END) as mem_err_drift_count,
        
        -- Count of machines with ANY critical drift
        COUNT(CASE 
            WHEN cpu_mape_status = 'Critical Drift' 
              OR mem_mape_status = 'Critical Drift' 
              OR cpu_rmse_status = 'Critical Drift' 
              OR mem_rmse_status = 'Critical Drift' 
              OR cpu_err_status = 'Critical Drift' 
              OR mem_err_status = 'Critical Drift' 
            THEN 1 
        END) as total_drifted_machines
    FROM drift_accuracy
    GROUP BY new_ts
)


SELECT * FROM drift_count
ORDER BY new_ts DESC
