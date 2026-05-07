WITH drift_accuracy AS (
    SELECT machine_id
    FROM {{ref('error_metrics')}}
)

SELECT * FROM drift_accuracy