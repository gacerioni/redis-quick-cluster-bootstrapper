# Redis Quick Cluster Bootstrapper

![Redis Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Redis_logo.svg/640px-Redis_logo.svg.png)

This repository contains a script that automatically sets up a 3-master Redis Cluster using Docker or pure redis processes copies in the runtime.

The cluster is intended for development, CI/CD Pipelines, and testing purposes. In other words, it offers a quick way to bootstrap a Redis Cluster.

## Features

- Automated Redis Cluster creation (3 master nodes)
- Cluster verification with basic `SET` and `GET` commands
- Configurable Redis version via environment variable (defaults to Redis 7.2.6)
- Ready to use with RedisInsight for monitoring

## ✨ Important Notice - To save you some time✨

**If you just need a quick docker/container image that will automatically build this redis oss/ce cluster (in the version you want) and offer all important ports at the host level, please go to [Step 5](#step-5-quick-container-setup)**

## Demo in PT-BR (recording the English version this weekend)

[![Watch the video](https://img.youtube.com/vi/qrhzZz5s9VI/0.jpg)](https://youtu.be/qrhzZz5s9VI)

## Running the Go Demo (tescontainers) passing an specific Redis Server version (good feature for CI)

This repository includes a Go demo program that creates a Redis cluster from scratch (testcontainers) and interacts with the Redis cluster.\
It uses testcontainers.com to run my custom redis oss image, in order to illustrate how we could run this from a CI Pipeline.

Please remember that if you were using Harness or Drone.io, this would be a simple Background Service step.

You can pick an specific Redis version and the script will do its best to find the proper release in the Redis Registry.\
We could also make redis from scratch, with the source code, but this might be an overkill or Plan B. :smile:

### Running the Go Demo

1. Navigate to the `go-demo` directory:
    ```bash
    cd go-demo-testcontainers
    ```

2. Fetch Go dependencies:
    ```bash
    go mod tidy
    ```

3. Run the demo program - this example runs the cluster @ version `6.2.11`:
    ```bash
    REDIS_VERSION=6.2.11 go run main.go
    ```

## How to Use

### 1. Download and Run the Bootstrap Script (local docker required for now)

To quickly set up a Redis Cluster, run the following commands:

```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/gacerioni/redis-quick-cluster-bootstrapper/refs/heads/master/redis-cluster-dockerized-instances.sh

# Make the script executable
chmod +x redis-cluster-dockerized-instances.sh

# Run the script to set up the Redis Cluster
# You can specify the Redis version with the REDIS_VERSION environment variable
REDIS_VERSION=7.2.6 ./redis-cluster-dockerized-instances.sh
```

#### 👽 Why Dockerized? 👽

To ensure consistent behavior across environments, we opted for Docker containers to run the Redis cluster. This increases compatibility, especially in varied or constrained environments like CI/CD pipelines. Docker ensures that all dependencies are handled in an isolated, predictable manner.

The [redis-cluster-bootstrapper.sh](redis-cluster-bootstrapper.sh) will teach you how to run the same cluster with pure Redis CE processes in the same runtime environment. You can MAKE your own redis, or use `redis-stack` (until we absorb the JSON and other modules).

**This script will:**

1.	Start 3 Redis nodes on ports 7000, 7001, and 7002.
2.	Create a Redis Cluster across these nodes.
3.	Verify the cluster status.
4.	Perform basic SET and GET operations to ensure the cluster functions correctly.

## 2. Verifying the Redis Cluster

After running the script, the following operations are performed automatically to verify the cluster:

- Cluster Status Check: The script checks if the Redis Cluster is up and running by verifying the cluster state.
- Ping Nodes: Each Redis node is pinged to ensure it’s responsive.
- Data Insertion and Retrieval: A test key (testkey) is inserted into the cluster, and the same key is retrieved from the node to confirm that the cluster is functional.

## 3. RedisInsight - Local Setup with Host Networking (Optional)

You can use RedisInsight to visualize and manage your Redis Cluster. Run the following command to launch RedisInsight in host network mode:

```bash
docker run -d --name redisinsight --net=host redis/redisinsight:latest
```

Access RedisInsight in your browser at:
```bash
http://<server_reachable_ip>:5540
```

Once open, follow these steps to connect RedisInsight to your Redis Cluster:

1.	Open RedisInsight in your browser.
2.	Click Add Redis Database.
3.	Use the following settings:
  -	Host: Enter the server’s private IP (use this instead of localhost if needed).
  -	Port: 7000 (or any other node port).
4.	Click Test Connection to ensure the connection is successful.

## 4. Clean Up

```bash
docker stop redis-node-7000 redis-node-7001 redis-node-7002 redisinsight
docker rm redis-node-7000 redis-node-7001 redis-node-7002 redisinsight
```

## Step 5: Quick Container Setup

Alternatively, you can run the entire Redis cluster setup with a custom Docker image:

```bash
docker run --rm -d \
  -p 7000:7000 \
  -p 7001:7001 \
  -p 7002:7002 \
  -p 17000-17002:17000-17002 \
  --name redis-quick-cluster \
  gacerioni/redis-quick-cluster:0.1.4-gabs
```

**This will spin up the Redis cluster and expose the necessary ports for external use.**

## 6. Danger Zone: Using Custom Redis Versions 🚨
You can select a specific Redis version for your cluster using my custom Docker image. The default version is `7.2.6`, but you can pass the desired version as an environment variable.

**Example: Running Redis version `6.2.11`:**

```bash
docker run --rm -it \
  -p 7000:7000 \
  -p 7001:7001 \
  -p 7002:7002 \
  -p 17000-17002:17000-17002 \
  -e REDIS_VERSION=6.2.11 \
  --name redis-quick-cluster \
  gacerioni/redis-quick-cluster:0.1.5-unstable
```

This command will:

1.	Search madison and pull the very specific Redis version 6.2.11.
2.	Start the cluster on ports 7000, 7001, and 7002.
3.	Verify the cluster setup and perform basic tests.


#### Important Note:

Once the demo starts, the Redis cluster will run for 5 minutes. During this time, you can connect to the cluster and interact with it in real-time.

Use tools like RedisInsight to visually monitor the cluster, or interact via the command line using the following command:

```bash
redis-cli -c -h 127.0.0.1 -p 7000
```

#### 
