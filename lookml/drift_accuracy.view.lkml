view: drift_accuracy {
  # 1. PHYSICAL TABLE REFERENCE
  # Tell Looker which physical BigQuery/Snowflake table or dbt view to query.
  sql_table_name: `krish-dev-data.ads_dev.drift_accuracy` ;;

  # ----------------------------------------------------
  # 2. DIMENSIONS (Fields you group by, slice by, or filter)
  # ----------------------------------------------------

  # Time Dimension Group: Automatically parses the timestamp into multiple options
  # (e.g. group by Hour, Day, Minute, Month)
  dimension_group: observation {
    type: time
    timeframes: [
      raw,
      time,
      minute,
      hour,
      date,
      week,
      month
    ]
    sql: ${TABLE}.new_ts ;;
    description: "The minute-by-minute observation timestamp"
  }

  # Unique machine identifier
  dimension: machine_id {
    type: string
    sql: ${TABLE}.machine_id ;;
    description: "The unique identifier of the physical cluster node"
  }

  # CPU MAPE Status (Healthy, Minor Drift, Critical Drift, Maturity Warmup)
  dimension: cpu_mape_status {
    type: string
    sql: ${TABLE}.cpu_mape_status ;;
    description: "Drift status of the CPU MAPE error metric"

    # HTML formatting to color-code tables directly in Looker UI
    html: 
      {% if value == 'Critical Drift' %}
        <span style="color: #ea4335; font-weight: bold;">🔴 {{ value }}</span>
      {% elsif value == 'Minor Drift' %}
        <span style="color: #fbbc05; font-weight: bold;">🟡 {{ value }}</span>
      {% elsif value == 'Maturity Warmup' %}
        <span style="color: #4285f4; font-style: italic;">🔵 {{ value }}</span>
      {% else %}
        <span style="color: #34a853;">🟢 {{ value }}</span>
      {% endif %} ;;
  }

  # Memory MAPE Status
  dimension: mem_mape_status {
    type: string
    sql: ${TABLE}.mem_mape_status ;;
    description: "Drift status of the Memory MAPE error metric"
    html: 
      {% if value == 'Critical Drift' %} <span style="color: #ea4335; font-weight: bold;">🔴 {{ value }}</span>
      {% elsif value == 'Minor Drift' %} <span style="color: #fbbc05; font-weight: bold;">🟡 {{ value }}</span>
      {% elsif value == 'Maturity Warmup' %} <span style="color: #4285f4; font-style: italic;">🔵 {{ value }}</span>
      {% else %} <span style="color: #34a853;">🟢 {{ value }}</span>
      {% endif %} ;;
  }

  # Yes/No Boolean Flag mapping to our dbt compiled flag
  dimension: is_drifted {
    type: yesno
    sql: ${TABLE}.is_drifted_flag = 1 ;;
    description: "Yes if the machine is experiencing ANY Critical Drift at this timestamp"
  }

  # ----------------------------------------------------
  # 3. MEASURES (Aggregated metrics like sums, counts, and averages)
  # ----------------------------------------------------

  # Total count of distinct active machines in the cluster
  measure: machine_count {
    type: count_distinct
    sql: ${machine_id} ;;
    description: "Total number of unique, active machines"
  }

  # Total count of distinct machines that have active drift
  measure: drifted_machine_count {
    type: count_distinct
    sql: ${machine_id} ;;
    # Dynamically filter this metric to only include rows where is_drifted = yes
    filters: [is_drifted: "yes"]
    description: "Total number of unique machines currently in Critical Drift"
  }

  # Dynamic Cluster Health Percentage KPI
  measure: cluster_health_score {
    type: number
    value_format_name: percent_1 # Automatically formats as e.g. "98.5%"
    sql: 1.0 - (SAFE_DIVIDE(${drifted_machine_count}, ${machine_count})) ;;
    description: "Percent of the cluster that is currently Healthy or in Minor Drift"
  }
}
