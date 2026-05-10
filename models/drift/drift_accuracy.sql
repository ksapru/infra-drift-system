WITH drift_accuracy AS (
    SELECT
        *,
        CASE
            WHEN rolling_avg_mape_cpu > mape_cpu_val THEN 1 
            ELSE 0
        END as cpu_mape_threshold,
        CASE
            WHEN rolling_avg_mape_mem > mape_mem_val THEN 1 
            ELSE 0
        END as mem_mape_threshold,
        CASE
            WHEN rolling_avg_rmse_cpu > sqrt(mse_cpu) THEN 1 
            ELSE 0
        END as cpu_rmse_threshold,
        CASE
            WHEN rolling_avg_rmse_mem > sqrt(mse_mem) THEN 1 
            ELSE 0
        END as mem_rmse_threshold,
        CASE
            WHEN rolling_avg_cpu_err > cpu_err THEN 1 
            ELSE 0
        END as cpu_err_threshold,
        CASE
            WHEN rolling_avg_mem_err > mem_err THEN 1 
            ELSE 0
        END as mem_err_threshold
    FROM {{ ref('rolling_metrics') }}
    WHERE
        new_ts IS NOT NULL
        AND rolling_avg_rmse_cpu IS NOT NULL -- Skips the initial "warm-up" rows
)

SELECT * FROM drift_accuracy
ORDER BY new_ts DESC, machine_id
