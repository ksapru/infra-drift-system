/*
    FULL ERROR METRICS SUITE
    Comprehensive rolling metrics for accuracy, bias, and MAPE.
*/

WITH actuals AS (
    SELECT 
        new_ts,
        machine_id,
        avg_cpu,
        avg_memory
    FROM {{ ref('initial_raw_dataset') }}
),

forecasts AS (
    SELECT 
        new_ts,
        forecast_cpu,
        forecast_memory
    FROM {{ ref('data_forecast') }}
),

base_errors AS (
    SELECT 
        a.new_ts,
        a.machine_id,
        a.avg_cpu,
        a.avg_memory,
        f.forecast_cpu,
        f.forecast_memory,
        -- Instant Errors
        (a.avg_cpu - f.forecast_cpu) as cpu_err,
        (a.avg_memory - f.forecast_memory) as mem_err,
        -- Instant MAPE
        SAFE_DIVIDE(ABS(a.avg_cpu - f.forecast_cpu), NULLIF(a.avg_cpu, 0)) * 100 as mape_cpu_val,
        SAFE_DIVIDE(ABS(a.avg_memory - f.forecast_memory), NULLIF(a.avg_memory, 0)) * 100 as mape_mem_val
    FROM actuals a
    LEFT JOIN forecasts f ON a.new_ts = f.new_ts
),

rolling_metrics AS (
    SELECT
        *,
        -- 1 & 2: Rolling MAE (Absolute Error)
        AVG(ABS(cpu_err)) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_error_cpu,
        AVG(ABS(mem_err)) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_error_memory,
        
        -- 3 & 4: Rolling Bias (Signed Error)
        AVG(cpu_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_signed_error_cpu,
        AVG(mem_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_signed_error_memory,
        
        -- 5 & 6: Rolling MAPE (Percentage Error)
        AVG(mape_cpu_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_mape_cpu,
        AVG(mape_mem_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_mape_memory
    FROM base_errors
)

SELECT * FROM rolling_metrics