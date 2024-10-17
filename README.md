# Redis Quick Cluster Bootstrapper

This repository contains a script that automatically sets up a 3-master Redis Cluster using Docker. The cluster is intended for development and testing purposes, offering a quick way to bootstrap a Redis Cluster.

## Features

- Automated Redis Cluster creation (3 master nodes)
- Cluster verification with basic `SET` and `GET` commands
- Ready to use with RedisInsight for monitoring

## How to Use

### 1. Download and Run the Bootstrap Script

To quickly set up a Redis Cluster, simply run the following commands:

```bash
# Download the setup script
wget https://raw.githubusercontent.com/gacerioni/redis-quick-cluster-bootstrapper/refs/heads/master/redis-cluster-dockerized-instances.sh

# Make the script executable
chmod +x redis-cluster-dockerized-instances.sh

# Run the script to set up the Redis Cluster
./redis-cluster-dockerized-instances.sh
```

This script will:

1.	Start 3 Redis nodes on ports 7000, 7001, and 7002.
2.	Create a Redis Cluster across these nodes.
3.	Verify the cluster status.
4.	Perform basic SET and GET operations to ensure the cluster is functioning correctly.

### 2. Verifying the Redis Cluster

After running the script, the following operations are performed automatically to verify the cluster:

-	Cluster Status Check: The script checks if the Redis Cluster is up and running by verifying the cluster state.
-	Ping Nodes: Each Redis node is pinged to ensure it’s responsive.
-	Data Insertion and Retrieval: A test key (testkey) is inserted into the cluster, and the same key is retrieved from the node to confirm that the cluster is functional.

### OPTIONAL - 3. RedisInsight - Local Setup with Host Networking

You can use RedisInsight to visualize and manage your Redis Cluster. Run the following command to launch RedisInsight:

```bash
docker run -d --name redisinsight -p 5540:5540 redis/redisinsight:latest
```

Access RedisInsight in your browser at:

```bash
http://localhost:5540
```

Once open, follow these steps to connect RedisInsight to your Redis Cluster:

1.	Open RedisInsight in your browser.
2.	Click Add Redis Database.
3.	Use the following settings:
 -	Host: host private's ip (if localhost fails)
 -	Port: 7000 (or any other node port)
4.	Click Test Connection to ensure the connection is successful.


### 4. Clean Up

```bash
docker stop redis-node-7000 redis-node-7001 redis-node-7002 redisinsight
docker rm redis-node-7000 redis-node-7001 redis-node-7002 redisinsight
```
