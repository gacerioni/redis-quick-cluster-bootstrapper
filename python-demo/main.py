import redis

def test_redis_connection():
    try:
        # Connect to the Redis cluster
        r = redis.RedisCluster(
            host='localhost',  # Replace with the correct host if needed
            port=7000,         # Start with one of the cluster ports
            decode_responses=True
        )

        # Test a PING command
        pong = r.ping()
        if pong:
            print("PING successful")

        # Test setting a key
        r.set('gabskey', 'gacerioni@gmail.com')
        print("SET command succeeded")

        # Test getting the key
        value = r.get('gabskey')
        print(f"GET Response: {value}")

    except Exception as e:
        print(f"Error connecting to Redis cluster: {e}")

if __name__ == "__main__":
    test_redis_connection()
