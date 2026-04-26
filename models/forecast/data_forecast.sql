
WITH base AS (
    SELECT
        new_ts,
        unique_machines,
        avg_cpu,
        avg_memory
    FROM `krish-dev-data.ads_dev.average_metrics`
),

# this computes the avg for the previous 7 time periods in minutes.
# this is essentially a moving average or smoothing technique
forecasted AS (
    SELECT 
        *,
        AVG(avg_cpu) OVER (ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS forecast_cpu,
        AVG(avg_memory) OVER (ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS forecast_memory
    FROM base
),

# calculates stuff like the mae, mape and mse
accuracy as (
    select 
        *,
        # compute the absolute errors
        ABS(forecast_cpu - avg_cpu) as error_cpu,
        ABS(forecast_memory - avg_memory) as error_memory,
        # compute the signed error
        forecast_cpu - avg_cpu as signed_error_cpu,
        forecast_memory - avg_memory as signed_error_memory,
        # compute the relative errors
        ABS(forecast_cpu - avg_cpu) / NULLIF(avg_cpu, 0) as mape_cpu,
        ABS(forecast_memory - avg_memory) / NULLIF(avg_memory, 0) as mape_memory
    from forecasted
)

SELECT * FROM accuracy;