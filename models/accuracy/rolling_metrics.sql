WITH rolling_metrics AS (
    SELECT 
        *
    FROM {{ref('error_metrics')}}
),

rolling_metrics_new AS (
    SELECT 
        *,
  -- PARTITION
  AVG(mape_cpu_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_mape_cpu,
  AVG(mape_mem_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_mape_mem,
  SQRT(AVG(mse_cpu) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as rolling_avg_rmse_cpu,
  SQRT(AVG(mse_mem) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as rolling_avg_rmse_mem,
  AVG(cpu_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_cpu_err,
  AVG(mem_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_mem_err
  FROM rolling_metrics
)

SELECT * FROM rolling_metrics_new
ORDER BY new_ts, machine_id
