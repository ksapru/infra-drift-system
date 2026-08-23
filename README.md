# Continuous Infrastructure Intelligence & Drift Detection

An enterprise-grade forecasting and anomaly detection suite designed to maintain high-fidelity performance baselines across large-scale infrastructure clusters. This system implements a **Continuous Accuracy** loop to detect silent performance degradation and resource drift before they impact production stability.

## Executive Summary
Modern infrastructure monitoring often fails to detect "silent" failures—machines that are technically "up" but have drifted from their expected performance baseline. This system bridges that gap by establishing a forecast and continuously grading every individual machine against it using a high-precision **True RMSE** engine.

## Core Architecture
The pipeline is structured as a multi-stage intelligence flow, moving from raw monitoring telemetry to actionable drift alerts.

## Intelligence Pillars

### I. Predictive Baselining
The system aggregates telemetry across the entire cluster to establish a "Source of Truth" for normal utilization. It utilizes high-resolution time-series forecasting to predict expected CPU and Memory demand at 1-minute intervals.

### II. Continuous Accuracy Engine (True RMSE)
Unlike standard error metrics that can be skewed by noise, we implement a **Root Mean Square Error (RMSE)** calculation. This provides a mathematically rigorous way to penalize large, dangerous performance outliers while smoothing out transient fluctuations.
- **Precision Grading**: Every machine is graded every minute against the predicted baseline.
- **Temporal Smoothing**: Accuracy scores are smoothed over a 7-minute window to ensure a high signal-to-noise ratio.

### III. Automated Drift Detection
The final layer identifies machines that have "drifted" from the baseline.
- **Anomaly Scoring**: Threshold-based logic flags machines whose real-time error exceeds their smoothed historical average.
- **Signal Integrity**: Integrated "warm-up" filters ensure that only fully-populated, reliable signals are passed to downstream alerting systems.

## Deployment & Integration
The system is built on **BigQuery** and **dbt**, designed for high scalability and seamless integration with **GCP Dataplex** for enterprise data governance.

Dashboard link: https://datastudio.google.com/reporting/00c9751a-fa21-4ccb-ada5-7e3985bb8ac4

### Execution
```bash
# Execute the complete intelligence pipeline
dbt run
```

---
*Developed by the Infrastructure Performance Engineering team.*
