# Continuous Infrastructure Accuracy & Drift Detection

A high-fidelity intelligence system designed to monitor, forecast, and detect performance drift across large-scale infrastructure clusters. This system provides a "Continuous Accuracy" loop by comparing real-time machine utilization against predictive baselines.

## The Mission
The core goal of this system is to identify when individual machines stop behaving like their cluster-wide baseline. By tracking **Continuous Accuracy**, we can detect silent failures, resource exhaustion, or "drift" before they trigger traditional high-utilization alerts.

## Intelligence Architecture

```mermaid
graph TD
    subgraph Staging
        Raw[initial_raw_dataset] --> Clean[cleaned_util]
    end

    subgraph Forecast
        Clean --> Avg[average_metrics]
        Avg --> Forecast[data_forecast]
    end

    subgraph Continuous Accuracy
        Forecast --> Error[error_metrics]
        Raw --> Error
        Error --> Roll[rolling_metrics]
    end

    subgraph Alerting
        Roll --> Drift[drift_accuracy]
    end

    style Drift fill:#f96,stroke:#333,stroke-width:4px
    style Forecast fill:#bbf,stroke:#333,stroke-width:2px
    style Raw fill:#ddd,stroke:#333,stroke-dasharray: 5 5
```

## Intelligence Pipeline

### 1. Baseline & Forecasting
The system aggregates cluster-wide utilization to establish a "source of truth" for normal behavior. It then generates continuous minute-by-minute predictions of expected CPU and Memory demand.

### 2. The Accuracy Engine (True RMSE)
Unlike simple averages, we implement a mathematically rigorous **Root Mean Square Error (RMSE)** engine. This ensures that even small fluctuations are tracked, but large, dangerous performance spikes are heavily penalized and flagged.
- **Error Scoring**: Every machine is graded every minute against the cluster forecast.
- **Smoothing**: Accuracy scores are smoothed over a 7-minute rolling window to differentiate between "noise" and "drift."

### 3. Drift Detection (The Alerting Layer)
The final stage compares a machine's **Instant Error** against its **Historical Average**. 
- **Drift Flags**: Triggered when a machine's performance error deviates significantly from its baseline.
- **Clean Signal**: The system automatically filters out "warm-up" noise, providing a 100% populated signal for downstream alerting.

## Technical Architecture
While the engine is powered by **dbt** and **BigQuery**, the focus is on the data flow:
1.  **Ingestion**: Cleaned monitoring logs.
2.  **Prediction**: Cluster-wide trend forecasting.
3.  **Accuracy**: Machine-level error calculation.
4.  **Drift**: Threshold-based anomaly detection.

## Execution
```bash
# Refresh the continuous accuracy intelligence
dbt run
```

---
*This project is part of the Infrastructure Health monitoring suite, integrated with GCP Dataplex for cross-cluster data discovery.*
