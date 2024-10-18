package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
	"github.com/docker/docker/api/types/container"
)

func main() {
	// Define default Redis version
	defaultRedisVersion := "7.2.6"
	redisVersion := os.Getenv("REDIS_VERSION")
	if redisVersion == "" {
		redisVersion = defaultRedisVersion
	}
	fmt.Printf("Using Redis version: %s\n", redisVersion)

	ctx := context.Background()

	// Create Redis cluster container request with host network mode and Redis version
	req := testcontainers.ContainerRequest{
		Image:        "gacerioni/redis-quick-cluster:0.1.5-unstable",
		Env:          map[string]string{"REDIS_VERSION": redisVersion}, // Pass the version via environment variable
		WaitingFor:   wait.ForLog("Cluster is up and running.").WithStartupTimeout(60 * time.Second), // Wait until the cluster is ready
		HostConfigModifier: func(hostConfig *container.HostConfig) {
			hostConfig.NetworkMode = "host" // Set host network mode for Linux
		},
	}

	// Start the container
	redisContainer, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		log.Fatalf("Failed to start the container: %v", err)
	}
	defer redisContainer.Terminate(ctx) // Clean up the container after the test

	// Since we are using host mode, the container is accessible via localhost on the specified ports
	fmt.Println("Using host network. Redis cluster running at: localhost")

	// Define static Redis cluster ports (as they are bound to the host in host network mode)
	redisHost := "localhost"
	redisPorts := []string{"7000", "7001", "7002"}

	// Construct addresses for Redis cluster
	redisAddrs := []string{
		fmt.Sprintf("%s:%s", redisHost, redisPorts[0]),
		fmt.Sprintf("%s:%s", redisHost, redisPorts[1]),
		fmt.Sprintf("%s:%s", redisHost, redisPorts[2]),
	}

	fmt.Printf("Redis ports: %s, %s, %s\n", redisPorts[0], redisPorts[1], redisPorts[2])
	fmt.Printf("Attempting to connect to Redis Cluster using addresses: %v\n", redisAddrs)

	// Use the static ports to connect to the Redis Cluster using go-redis
	rdb := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: redisAddrs,
	})

	// Test connection with a PING command
	pong, err := rdb.Ping(ctx).Result()
	if err != nil {
		fmt.Printf("Cluster addresses: %v\n", redisAddrs)
		log.Fatalf("Could not connect to Redis cluster: %v", err)
	}
	fmt.Println("PING Response:", pong)

	// Set and Get test
	err = rdb.Set(ctx, "testkey", "Hello, Redis Cluster!", 0).Err()
	if err != nil {
		fmt.Printf("Cluster addresses: %v\n", redisAddrs)
		log.Fatalf("Failed to SET key: %v", err)
	}
	fmt.Println("SET command succeeded")

	val, err := rdb.Get(ctx, "testkey").Result()
	if err != nil {
		fmt.Printf("Cluster addresses: %v\n", redisAddrs)
		log.Fatalf("Failed to GET key: %v", err)
	}
	fmt.Println("GET Response:", val)

	// Sleep for 5 minutes (300 seconds)
	fmt.Println("Sleeping for 5 minutes to allow interaction with the Redis cluster...")
	time.Sleep(5 * time.Minute)
}