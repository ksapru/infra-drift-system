WITH drift_accuracy AS (
    SELECT 
        *,
    FROM {{ref('rolling_metrics')}}
)

SELECT * FROM drift_accuracy