-- created_at: 2026-04-28T21:19:56.033136+00:00
-- finished_at: 2026-04-28T21:19:59.908235+00:00
-- elapsed: 3.9s
-- outcome: success
-- dialect: bigquery
-- node_id: not available
-- query_id: E46SVfnJZSkXZsUsboKBA2pUZqA
-- desc: execute adapter call
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "infra_drift_system", "target_name": "dev"} */

    select distinct schema_name from `krish-dev-data`.INFORMATION_SCHEMA.SCHEMATA;
  ;
-- created_at: 2026-04-28T21:20:00.300718+00:00
-- finished_at: 2026-04-28T21:20:03.748895+00:00
-- elapsed: 3.4s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.initial_raw_dataset
-- query_id: yTKYq74xkouZPDiMdrgbcxxufff
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `krish-dev-data`.`ads_dev`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-04-28T21:20:03.765361+00:00
-- finished_at: 2026-04-28T21:20:05.920387+00:00
-- elapsed: 2.2s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.initial_raw_dataset
-- query_id: Vfn54O0nZ4tf9kBANZFna1ItbsC
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
-- created_at: 2026-04-28T21:20:05.974273+00:00
-- finished_at: 2026-04-28T21:20:08.688740+00:00
-- elapsed: 2.7s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.cleaned_util
-- query_id: abpjFddYqD6RHs3reGYfvWXcYhT
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
-- created_at: 2026-04-28T21:20:08.981435+00:00
-- finished_at: 2026-04-28T21:20:18.172089+00:00
-- elapsed: 9.2s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.average_metrics
-- query_id: arkatwT3GIF2AMoWHbjGMIxxWhv
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
-- created_at: 2026-04-28T21:20:18.507444+00:00
-- finished_at: 2026-04-28T21:20:37.282427+00:00
-- elapsed: 18.8s
-- outcome: success
-- dialect: bigquery
-- node_id: model.infra_drift_system.data_forecast
-- query_id: 8UNnS4qn601o8KRmt0kl4gHUTOL
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
    SELECT 
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
