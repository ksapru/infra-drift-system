/*
    FIXED ERROR METRICS
    Issue: Join was failing because timestamps had seconds/milliseconds.
    Fix: Truncating both sides to the MINUTE to ensure a perfect join.
*/

WITH actuals AS (
    SELECT 
        -- Rounding to the minute so it matches the forecast buckets
        TIMESTAMP_TRUNC(new_ts, MINUTE) as joined_ts,
        machine_id,
        avg_cpu,
        avg_memory
    FROM {{ ref('initial_raw_dataset') }}
),

forecasts AS (
    SELECT 
        TIMESTAMP_TRUNC(new_ts, MINUTE) as joined_ts,
        forecast_cpu,
        forecast_memory
    FROM {{ ref('data_forecast') }}
),

base_errors AS (
    SELECT 
        a.joined_ts as new_ts,
        a.machine_id,
        a.avg_cpu,
        a.avg_memory,
        f.forecast_cpu,
        f.forecast_memory,
        -- Instant Errors
        (a.avg_cpu - f.forecast_cpu) as cpu_err,
        (a.avg_memory - f.forecast_memory) as mem_err,
        SAFE_DIVIDE(ABS(a.avg_cpu - f.forecast_cpu), NULLIF(a.avg_cpu, 0)) * 100 as mape_cpu_val,
        SAFE_DIVIDE(ABS(a.avg_memory - f.forecast_memory), NULLIF(a.avg_memory, 0)) * 100 as mape_mem_val
    FROM actuals a
    INNER JOIN forecasts f ON a.joined_ts = f.joined_ts
),

rolling_metrics AS (
    SELECT
        *,
        -- Rolling MAE (Absolute Error)
        AVG(ABS(cpu_err)) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_error_cpu,
        AVG(ABS(mem_err)) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_error_memory,
        
        -- Rolling Bias (Signed Error)
        AVG(cpu_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_signed_error_cpu,
        AVG(mem_err) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_signed_error_memory,
        
        -- Rolling MAPE
        AVG(mape_cpu_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_mape_cpu,
        AVG(mape_mem_val) OVER (PARTITION BY machine_id ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as rolling_avg_mape_memory
    FROM base_errors
)

SELECT * FROM rolling_metrics