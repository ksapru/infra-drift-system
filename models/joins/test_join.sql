--! depends_on {{ ref('error_metrics') }} {{ ref('data_forecast') }}
WITH join_data AS (
    SELECT 
        t1.*,
        t2.rolling_avg_error_cpu,
        t2.rolling_avg_error_memory,
        t2.rolling_avg_signed_error_cpu,
        t2.rolling_avg_signed_error_memory,
        t2.rolling_avg_mape_cpu,
        t2.rolling_avg_mape_memory
    FROM {{ref('data_forecast')}} t1
    INNER JOIN {{ ref('error_metrics') }} t2
    ON t1.new_ts = t2.new_ts
    ORDER BY t1.new_ts
)

SELECT * FROM join_data
