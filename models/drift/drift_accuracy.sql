WITH drift_accuracy AS (
    SELECT *
    FROM {{ref('error_metrics')}}
)

SELECT * FROM drift_accuracy