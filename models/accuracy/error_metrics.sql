WITH base AS (
    SELECT
    new_ts,
    error_cpu,
    error_memory,
    signed_error_cpu,
    signed_error_memory,
    mape_cpu,
    mape_memory
    FROM {{ ref('data_forecast') }}
),

rolling AS (
    SELECT
        new_ts,
        AVG(error_cpu) OVER (ORDER BY new_ts ROWS BETWEEN  6 PRECEDING AND CURRENT ROW) as rolling_avg_error_cpu,
        AVG(error_memory) OVER (ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_error_memory,
        AVG(signed_error_cpu) OVER (ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_signed_error_cpu,
        AVG(signed_error_memory) OVER (ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_signed_error_memory,
        AVG(mape_cpu) OVER (ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_mape_cpu,
        AVG(mape_memory) OVER (ORDER BY new_ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_mape_memory
    FROM base
)

SELECT * FROM rolling
   