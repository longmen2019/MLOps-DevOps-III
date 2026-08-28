from kafka import KafkaProducer            # Import KafkaProducer to send messages to Kafka
from fastapi import HTTPException          # Import HTTPException for FastAPI error handling
from producer_schema import ProduceMessage # Import the Pydantic schema for incoming messages
import json                                # Import JSON for serialization


# -------------------------------------------------------------------
# Constant values
# -------------------------------------------------------------------
KAFKA_BROKER_URL = "localhost:29092"        # Address of the Kafka broker
KAFKA_TOPIC = "fastapi-topic"              # Kafka topic where messages will be sent
PRODUCER_CLIENT_ID = "fastapi_producer"    # Identifier for this Kafka producer instance


# -------------------------------------------------------------------
# Serializer function
# -------------------------------------------------------------------
def serializer(message):                   
    return json.dumps(message).encode("utf-8")  
    # Converts Python dict → JSON string → bytes (Kafka requires bytes)


# -------------------------------------------------------------------
# Kafka Producer instance
# -------------------------------------------------------------------
producer = KafkaProducer(
    api_version=(0, 8, 0),                 # Kafka API version used by the client
    bootstrap_servers=KAFKA_BROKER_URL,    # Kafka broker connection address
    value_serializer=serializer,           # Function to serialize message values
    client_id=PRODUCER_CLIENT_ID           # Unique ID for this producer
)


# -------------------------------------------------------------------
# Function to send messages to Kafka
# -------------------------------------------------------------------
def produce_kafka_message(messageRequest: ProduceMessage):
    try:
        payload = {"message": messageRequest.message}  
        # Convert Pydantic model → dict containing only the message field

        producer.send(KAFKA_TOPIC, payload)  
        # Send the serialized payload to the Kafka topic

        producer.flush()                   
        # Force all buffered messages to be delivered immediately

    except Exception as error:
        print(error)                       
        # Print the error for debugging

        raise HTTPException(
            status_code=500,
            detail="Failed to send message to Kafka"
        )
        # Raise a FastAPI-friendly error if sending fails
