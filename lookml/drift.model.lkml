# Define the database connection you set up in your Looker Admin panel
connection: "your_bigquery_connection"

# Include all .view.lkml files in this directory
include: "*.view.lkml"

# ----------------------------------------------------
# EXPLORE: This is the user interface entrypoint in Looker
# ----------------------------------------------------
explore: drift_accuracy {
  label: "Infrastructure Accuracy & Drift Monitoring"
  description: "Analyze machine-level accuracy deviations and cluster drift anomalies over time."
  
  # Set a default group label in the Looker menu
  group_label: "Core Cluster Telemetry"
}
