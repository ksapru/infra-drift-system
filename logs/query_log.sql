-- created_at: 2026-04-26T20:14:03.844164+00:00
-- finished_at: 2026-04-26T20:14:07.618160+00:00
-- elapsed: 3.8s
-- outcome: success
-- dialect: bigquery
-- node_id: not available
-- query_id: QED2qDD95xbzm9ikqMZaKixD54q
-- desc: execute adapter call
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "infra_drift_system", "target_name": "dev"} */

    select distinct schema_name from `krish-dev-data`.INFORMATION_SCHEMA.SCHEMATA;
  ;
-- created_at: 2026-04-26T20:14:07.739610+00:00
-- finished_at: 2026-04-26T20:14:10.511745+00:00
-- elapsed: 2.8s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.initial_raw_dataset
-- query_id: JLP1WNP19mYTEMfDICw0xW3y20A
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `krish-dev-data`.`ads_dev`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-04-26T20:14:10.540334+00:00
-- finished_at: 2026-04-26T20:14:12.519839+00:00
-- elapsed: 2.0s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.initial_raw_dataset
-- query_id: 6VAp7x2j8Py911JOfWKemkHj9PI
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.infra_drift_system.initial_raw_dataset", "profile_name": "infra_drift_system", "target_name": "dev"} */


  create or replace view `krish-dev-data`.`ads_dev`.`initial_raw_dataset`
  OPTIONS()
  as SELECT
  CASE 
    WHEN time BETWEEN 1e12 AND 1e14 THEN TIMESTAMP_MILLIS(time)
    WHEN time BETWEEN 1e9 AND 1e12 THEN TIMESTAMP_MILLIS(time)
  ELSE NULL
  END as ts,
  priority,
  machine_id,
  resource_request.cpus AS cpu,
  resource_request.memory AS memory
FROM `krish-dev-data`.`ads_raw`.`ads_raw_cluster_m5`
WHERE resource_request.cpus IS NOT NULL
  AND resource_request.memory IS NOT NULL;

;
-- created_at: 2026-04-26T20:14:12.538124+00:00
-- finished_at: 2026-04-26T20:14:14.695368+00:00
-- elapsed: 2.2s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.cleaned_util
-- query_id: SycQlsVQTVpQzA1rZZOjIC4vNNg
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.infra_drift_system.cleaned_util", "profile_name": "infra_drift_system", "target_name": "dev"} */


  create or replace view `krish-dev-data`.`ads_dev`.`cleaned_util`
  OPTIONS()
  as SELECT
  TIMESTAMP_TRUNC(ts, MINUTE) AS new_ts,
  machine_id,
  cpu,
  memory,
  priority
FROM `krish-dev-data`.`ads_dev`.`initial_raw_dataset`
WHERE ts IS NOT NULL;

;
-- created_at: 2026-04-26T20:14:14.894782+00:00
-- finished_at: 2026-04-26T20:14:24.381499+00:00
-- elapsed: 9.5s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.average_metrics
-- query_id: AKqMZoM2ERctk9VOgD5Hk4P5TPB
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.infra_drift_system.average_metrics", "profile_name": "infra_drift_system", "target_name": "dev"} */

  
    

    create or replace table `krish-dev-data`.`ads_dev`.`average_metrics`
      
    
    

    
    OPTIONS()
    as (
      SELECT 
    new_ts,
    COUNT(DISTINCT machine_id) as unique_machines,
    AVG(CPU) as avg_cpu,
    AVG(memory) as avg_memory
FROM `krish-dev-data`.`ads_dev`.`cleaned_util`
GROUP BY 1
    );
  ;
-- created_at: 2026-04-26T20:14:24.395256+00:00
-- finished_at: 2026-04-26T20:14:44.532646+00:00
-- elapsed: 20.1s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.data_forecast
-- query_id: pNxUZee5TKVLlyqUM2KnKIobNNp
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.infra_drift_system.data_forecast", "profile_name": "infra_drift_system", "target_name": "dev"} */

  
    

    create or replace table `krish-dev-data`.`ads_dev`.`data_forecast`
      
    
    

    
    OPTIONS()
    as (
      
WITH base AS (
    SELECT
        new_ts,
        unique_machines,
        avg_cpu,
        avg_memory
    FROM `krish-dev-data`.`ads_dev`.`average_metrics`
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

SELECT * FROM accuracy
    );
  ;
