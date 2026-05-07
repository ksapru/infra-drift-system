WITH actuals AS (
    SELECT 
        TIMESTAMP_TRUNC(new_ts, MINUTE) as joined_ts,
        machine_id,
        AVG(avg_cpu) as avg_cpu,
        AVG(avg_memory) as avg_memory
    FROM {{ ref('initial_raw_dataset') }}
    GROUP BY 1, 2
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
    LEFT JOIN forecasts f ON a.joined_ts = f.joined_ts
)

SELECT * FROM base_errors