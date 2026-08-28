from fastapi import FastAPI, BackgroundTasks
from confluent_kafka.admin import AdminClient, NewTopic
from confluent_kafka import Producer
from contextlib import asynccontextmanager
from producer_schema import ProduceMessage

# -------------------------------------------------------------------
# Constants Section
# -------------------------------------------------------------------
KAFKA_BROKER_URL = "localhost:29092"
KAFKA_TOPIC = "fastapi-topic"

# Global producer instance
producer = Producer({"bootstrap.servers": KAFKA_BROKER_URL})


# -------------------------------------------------------------------
# Lifespan context manager (runs at startup and shutdown)
# -------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    admin = AdminClient({"bootstrap.servers": KAFKA_BROKER_URL})

    # Fetch metadata to check existing topics
    metadata = admin.list_topics(timeout=10)

    # Create topic if missing
    if KAFKA_TOPIC not in metadata.topics:
        admin.create_topics([
            NewTopic(KAFKA_TOPIC, num_partitions=1, replication_factor=1)
        ])

    yield


# -------------------------------------------------------------------
# FastAPI Application Instance
# -------------------------------------------------------------------
app = FastAPI(lifespan=lifespan)


# -------------------------------------------------------------------
# Kafka Producer Function
# -------------------------------------------------------------------
def produce_kafka_message(messageRequest: ProduceMessage):
    producer.produce(
        topic=KAFKA_TOPIC,
        value=messageRequest.message.encode("utf-8")
    )
    producer.flush()


# -------------------------------------------------------------------
# POST Endpoint to Produce Kafka Message
# -------------------------------------------------------------------
@app.post("/produce/message", tags=["Produce Message"])
async def produce_message(messageRequest: ProduceMessage, background_tasks: BackgroundTasks):
    background_tasks.add_task(produce_kafka_message, messageRequest)
    return {"message": "Message received. Thank you for sending a message."}
