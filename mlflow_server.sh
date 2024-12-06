#!/bin/bash

case "$1" in
  start)
    echo "Starting MLflow server..."
    nohup mlflow server --host 127.0.0.1 --port 5000 > mlflow.log 2>&1 &
    echo "MLflow server started."
    ;;
  stop)
    echo "Stopping MLflow server..."
    pkill -f "mlflow server --host 127.0.0.1 --port 5000"
    echo "MLflow server stopped."
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    ;;
esac
