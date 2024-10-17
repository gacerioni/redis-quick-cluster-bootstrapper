#!/bin/bash

# Accept Redis version from environment variable, default to 7.2.6 if not provided
REDIS_VERSION=${REDIS_VERSION:-7.2.6}

# Define Redis node ports
REDIS_PORTS=("7000" "7001" "7002")

# Start Redis nodes
for PORT in "${REDIS_PORTS[@]}"; do
  echo "Starting Redis node on port $PORT with Redis version $REDIS_VERSION..."
  docker run -d --name redis-node-$PORT \
    --net host \
    redis:$REDIS_VERSION \
    redis-server --port $PORT --cluster-enabled yes --cluster-config-file nodes-$PORT.conf --appendonly yes
done

# Wait for Redis nodes to start
echo "Waiting for Redis nodes to initialize..."
sleep 10

# Get host IP (adjust if necessary)
HOST_IP=$(hostname -I | awk '{print $1}')

# Create Redis Cluster
echo "Creating Redis Cluster..."
docker exec redis-node-7000 redis-cli --cluster create \
  $HOST_IP:7000 $HOST_IP:7001 $HOST_IP:7002 \
  --cluster-replicas 0 --cluster-yes

# Retry logic for checking cluster state
echo "Verifying cluster status..."

MAX_RETRIES=5
RETRY_INTERVAL=2
RETRIES=0

while [ $RETRIES -lt $MAX_RETRIES ]; do
  # Capture and print cluster info
  CLUSTER_STATE=$(docker exec redis-node-7000 redis-cli -p 7000 cluster info | grep "cluster_state" | tr -d '\r\n')

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
docker exec redis-node-7000 redis-cli -p 7000 cluster nodes

# Basic ping test on each node
echo "Pinging Redis nodes..."
for PORT in "${REDIS_PORTS[@]}"; do
  PING_RESPONSE=$(docker exec redis-node-$PORT redis-cli -p $PORT ping)
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
docker exec redis-node-7000 redis-cli -p 7000 set testkey "Hello, Redis Cluster!"
GET_RESPONSE=$(docker exec redis-node-7000 redis-cli -p 7000 get testkey)

if [[ $GET_RESPONSE == "Hello, Redis Cluster!" ]]; then
  echo "Data correctly stored and retrieved on the same node."
else
  echo "Failed to retrieve data on the same node."
  exit 1
fi

echo "Redis Cluster setup and validation completed successfully!"
