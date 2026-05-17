--! depends_on {{ ref('rolling_metrics') }} {{ ref('data_forecast') }}
WITH join_data AS (
    SELECT 
        t1.*,
        t2.machine_id,
        t2.rolling_avg_rmse_cpu as rolling_rmse_cpu,
        t2.rolling_avg_rmse_mem as rolling_rmse_mem,
        t2.rolling_avg_cpu_err as rolling_cpu_err,
        t2.rolling_avg_mem_err as rolling_mem_err,
        t2.rolling_avg_mape_cpu as rolling_mape_cpu,
        t2.rolling_avg_mape_mem as rolling_mape_mem
    FROM {{ref('data_forecast')}} t1
    INNER JOIN {{ ref('rolling_metrics') }} t2
    ON t1.new_ts = t2.new_ts
)

SELECT * FROM join_data
ORDER BY new_ts, machine_id
