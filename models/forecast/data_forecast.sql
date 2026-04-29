WITH base AS (
    SELECT
        new_ts,
        unique_machines,
        avg_cpu,
        avg_memory
    FROM {{ ref('average_metrics') }}
    ),

    # this computes the avg for the previous 7 time periods in minutes.
    forecasted AS (
    SELECT 
        *,
        # 7 PRECEDING and 1 PRECEDING gives you exactly 7 historical rows
        AVG(avg_cpu) OVER (ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS forecast_cpu,
        AVG(avg_memory) OVER (ORDER BY new_ts ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS forecast_memory
    FROM base
    ),

    # calculates stuff like the mae, mape and mse
    accuracy as (
    SELECT 
        *,
        # compute the absolute errors
        ABS(forecast_cpu - avg_cpu) as error_cpu,
        ABS(forecast_memory - avg_memory) as error_memory,
        # compute the signed error
        avg_cpu - forecast_cpu as signed_error_cpu,
        avg_memory - forecast_memory as signed_error_memory,
        # compute the relative errors
        (ABS(forecast_cpu - avg_cpu) / NULLIF(avg_cpu, 0)) * 100 as mape_cpu,
        (ABS(forecast_memory - avg_memory) / NULLIF(avg_memory, 0)) * 100 as mape_memory
    from forecasted
    )

    SELECT * FROM accuracy