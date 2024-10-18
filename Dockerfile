# Use Ubuntu as the base image
FROM ubuntu:20.04

# Set environment variable to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies (but NOT Redis)
RUN apt-get update && apt-get install -y \
    lsb-release \
    curl \
    gpg \
    build-essential \
    libjemalloc-dev \
    tcl \
    wget \
    bash

# Add Redis APT repository
RUN curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg \
    && chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list \
    && apt-get update

# Copy the Redis Cluster creation script
COPY redis-cluster-bootstrapper.sh /usr/local/bin/redis-cluster-bootstrapper.sh

# Ensure the script is executable
RUN chmod +x /usr/local/bin/redis-cluster-bootstrapper.sh

# Entry point for the script
CMD ["/usr/local/bin/redis-cluster-bootstrapper.sh"]