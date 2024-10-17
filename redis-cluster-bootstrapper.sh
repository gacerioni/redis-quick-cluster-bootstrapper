#!/bin/bash

# Define Redis node ports
REDIS_PORTS=("7000" "7001" "7002")

# Start Redis nodes as processes
for PORT in "${REDIS_PORTS[@]}"; do
  echo "Starting Redis node on port $PORT..."
  redis-server --port $PORT \
    --cluster-enabled yes \
    --cluster-config-file nodes-$PORT.conf \
    --appendonly yes \
    --protected-mode no \
    --daemonize yes
  
  sleep 2

  # Add log to check if Redis process is running
  if ps aux | grep -v grep | grep "redis-server.*:$PORT"; then
    echo "Redis node on port $PORT started successfully."
  else
    echo "Failed to start Redis node on port $PORT."
    exit 1
  fi
done

# Wait for Redis nodes to start
echo "Waiting for Redis nodes to initialize..."
sleep 10

# Get host IP (adjust if necessary)
HOST_IP=127.0.0.1

# Create Redis Cluster
echo "Creating Redis Cluster..."
redis-cli --cluster create \
  $HOST_IP:7000 $HOST_IP:7001 $HOST_IP:7002 \
  --cluster-replicas 0 --cluster-yes

# Retry logic for checking cluster state
echo "Verifying cluster status..."

MAX_RETRIES=5
RETRY_INTERVAL=2
RETRIES=0

while [ $RETRIES -lt $MAX_RETRIES ]; do
  CLUSTER_STATE=$(redis-cli -p 7000 cluster info | grep "cluster_state" | tr -d '\r\n')

  if [[ "$CLUSTER_STATE" == "cluster_state:ok" ]]; then
    echo "Cluster is up and running."
    break
  else
    echo "Cluster state is $CLUSTER_STATE, retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
    RETRIES=$((RETRIES+1))
  fi
done

if [[ "$CLUSTER_STATE" != "cluster_state:ok" ]]; then
  echo "Cluster creation failed after $MAX_RETRIES attempts."
  exit 1
fi

# Check Redis nodes
echo "Checking cluster nodes..."
redis-cli -p 7000 cluster nodes

# Basic ping test on each node
echo "Pinging Redis nodes..."
for PORT in "${REDIS_PORTS[@]}"; do
  PING_RESPONSE=$(redis-cli -p $PORT ping)
  if [[ $PING_RESPONSE == "PONG" ]]; then
    echo "Node $PORT is responsive."
  else
    echo "Node $PORT is not responding."
    exit 1
  fi
done

# Test data insertion and retrieval on the same node (port 7000)
echo "Testing SET and GET commands on the same node..."

# Set and Get on the same node to avoid MOVED redirection
redis-cli -p 7000 set testkey "Hello, Redis Cluster!"
GET_RESPONSE=$(redis-cli -p 7000 get testkey)

if [[ $GET_RESPONSE == "Hello, Redis Cluster!" ]]; then
  echo "Data correctly stored and retrieved on the same node."
else
  echo "Failed to retrieve data on the same node."
  exit 1
fi

echo "Redis Cluster setup and validation completed successfully!"

# Keep the container running by tailing the Redis logs (or any other file)
echo "Cluster setup complete. Keeping container alive..."
tail -f /dev/null