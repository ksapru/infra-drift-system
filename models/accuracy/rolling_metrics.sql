WITH rolling_metrics AS (
    SELECT 
        *
    FROM {{ref('error_metrics')}}
),

rolling_metrics_new AS (
    SELECT 
        *,
        -- PARTITION: Increased to 30-minute window for a stable statistical baseline
        AVG(mape_cpu_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_avg_mape_cpu,
        STDDEV_POP(mape_cpu_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_std_mape_cpu,

        AVG(mape_mem_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_avg_mape_mem,
        STDDEV_POP(mape_mem_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_std_mape_mem,

        SQRT(AVG(mse_cpu) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)) as rolling_avg_rmse_cpu,
        STDDEV_POP(SQRT(mse_cpu)) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_std_rmse_cpu,

        SQRT(AVG(mse_mem) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)) as rolling_avg_rmse_mem,
        STDDEV_POP(SQRT(mse_mem)) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_std_rmse_mem,

        AVG(cpu_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_avg_cpu_err,
        STDDEV_POP(cpu_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_std_cpu_err,

        AVG(mem_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_avg_mem_err,
        STDDEV_POP(mem_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as rolling_std_mem_err,

        -- Track how many minutes of history we have for this machine (minimum maturity check)
        COUNT(*) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as window_maturity
    FROM rolling_metrics
)

SELECT * FROM rolling_metrics_new
ORDER BY new_ts, machine_id
