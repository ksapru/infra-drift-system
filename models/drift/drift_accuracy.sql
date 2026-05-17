WITH drift_accuracy AS (
    SELECT
        *,
        -- 3σ + FLOOR LOGIC: Less sensitive to jitter, only alerts on significant outliers.
        -- We require window_maturity > 10 to ensure we have a stable baseline.

        -- CPU MAPE Drift
        CASE
            WHEN window_maturity < 10 THEN 'Maturity Warmup'
            WHEN mape_cpu_val > (rolling_avg_mape_cpu + 3 * rolling_std_mape_cpu) AND mape_cpu_val > 15 THEN 'Critical Drift'
            WHEN mape_cpu_val > (rolling_avg_mape_cpu + 2 * rolling_std_mape_cpu) AND mape_cpu_val > 10 THEN 'Minor Drift'
            ELSE 'Healthy'
        END as cpu_mape_status,

        -- Memory MAPE Drift
        CASE
            WHEN window_maturity < 10 THEN 'Maturity Warmup'
            WHEN mape_mem_val > (rolling_avg_mape_mem + 3 * rolling_std_mape_mem) AND mape_mem_val > 15 THEN 'Critical Drift'
            WHEN mape_mem_val > (rolling_avg_mape_mem + 2 * rolling_std_mape_mem) AND mape_mem_val > 10 THEN 'Minor Drift'
            ELSE 'Healthy'
        END as mem_mape_status,

        -- CPU RMSE Drift (Outlier detection)
        CASE
            WHEN window_maturity < 10 THEN 'Maturity Warmup'
            WHEN sqrt(mse_cpu) > (rolling_avg_rmse_cpu + 3 * rolling_std_rmse_cpu) AND sqrt(mse_cpu) > 0.1 THEN 'Critical Drift'
            WHEN sqrt(mse_cpu) > (rolling_avg_rmse_cpu + 2 * rolling_std_rmse_cpu) AND sqrt(mse_cpu) > 0.05 THEN 'Minor Drift'
            ELSE 'Healthy'
        END as cpu_rmse_status,

        -- Memory RMSE Drift
        CASE
            WHEN window_maturity < 10 THEN 'Maturity Warmup'
            WHEN sqrt(mse_mem) > (rolling_avg_rmse_mem + 3 * rolling_std_rmse_mem) AND sqrt(mse_mem) > 0.1 THEN 'Critical Drift'
            WHEN sqrt(mse_mem) > (rolling_avg_rmse_mem + 2 * rolling_std_rmse_mem) AND sqrt(mse_mem) > 0.05 THEN 'Minor Drift'
            ELSE 'Healthy'
        END as mem_rmse_status,

        -- CPU Absolute Error Drift
        CASE
            WHEN window_maturity < 10 THEN 'Maturity Warmup'
            WHEN cpu_err > (rolling_avg_cpu_err + 3 * rolling_std_cpu_err) AND cpu_err > 0.1 THEN 'Critical Drift'
            WHEN cpu_err > (rolling_avg_cpu_err + 2 * rolling_std_cpu_err) AND cpu_err > 0.05 THEN 'Minor Drift'
            ELSE 'Healthy'
        END as cpu_err_status,

        -- Memory Absolute Error Drift
        CASE
            WHEN window_maturity < 10 THEN 'Maturity Warmup'
            WHEN mem_err > (rolling_avg_mem_err + 3 * rolling_std_mem_err) AND mem_err > 0.1 THEN 'Critical Drift'
            WHEN mem_err > (rolling_avg_mem_err + 2 * rolling_std_mem_err) AND mem_err > 0.05 THEN 'Minor Drift'
            ELSE 'Healthy'
        END as mem_err_status
    FROM {{ ref('rolling_metrics') }}
    WHERE new_ts IS NOT NULL
)

-- FINAL SELECT: Returning to Machine-Level Grain 
SELECT 
    *,
    CASE 
        WHEN cpu_mape_status = 'Critical Drift' 
          OR mem_mape_status = 'Critical Drift' 
          OR cpu_rmse_status = 'Critical Drift' 
          OR mem_rmse_status = 'Critical Drift' 
          OR cpu_err_status = 'Critical Drift' 
          OR mem_err_status = 'Critical Drift' 
        THEN 1 
        ELSE 0 
    END as is_drifted_flag
FROM drift_accuracy
ORDER BY new_ts DESC, machine_id
