from fastapi import FastAPI
import asyncio
from kafka import KafkaConsumer
import json
import re

# Constant Section
KAFKA_BROKER_URL = "localhost:29092"
KAFKA_TOPIC = 'fastapi-topic'
KAFKA_CONSUMER_ID = 'fastapi-consumer'

stop_polling_event = asyncio.Event()
app = FastAPI()


def json_deserializer(value):
    if value is None:
        return None
    try:
        return json.loads(value.decode('utf-8'))
    except Exception as e:
        print(f"Unable to decode: {e}")
        return None


# NEW: sanitize topic names
def sanitize_topic(topic: str) -> str:
    # Replace spaces with hyphens
    topic = topic.replace(" ", "-")

    # Remove invalid characters (anything not alphanumeric, ., _, -)
    topic = re.sub(r"[^a-zA-Z0-9._-]", "", topic)

    # Lowercase for consistency
    topic = topic.lower()

    # If empty after sanitizing, fallback to default
    if topic == "":
        topic = "fastapi-topic"

    return topic


def create_kafka_consumer(topic: str):
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=[KAFKA_BROKER_URL],
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        group_id=KAFKA_CONSUMER_ID,
        value_deserializer=json_deserializer
    )
    return consumer


async def poll_consumer(consumer: KafkaConsumer):
    try:
        while not stop_polling_event.is_set():
            print("Trying to Poll again")
            records = consumer.poll(5000, 250)
            if records:
                for record in records.values():
                    for message in record:
                        if message.value:
                            m = message.value.get("message")
                            print(f"Received the message {m} from the topic of {message.topic}")
                        else:
                            print("Received non-JSON or empty message")
            await asyncio.sleep(5)
    except Exception as e:
        print(f"Errors available {e}")
    finally:
        print("Closing the consumer")
        consumer.close()


tasklist = []


# POST endpoint with sanitization
@app.post("/trigger")
async def trigger_polling(topic: str = "fastapi-topic"):
    sanitized = sanitize_topic(topic)

    if not tasklist:
        stop_polling_event.clear()
        consumer = create_kafka_consumer(sanitized)
        task = asyncio.create_task(poll_consumer(consumer=consumer))
        tasklist.append(task)

        return {
            "input_topic": topic,
            "sanitized_topic": sanitized,
            "status": f"kafka polling started for topic '{sanitized}'"
        }

    return {"status": "kafka polling already triggered"}


@app.get("/stop-trigger")
async def stop_trigger():
    stop_polling_event.set()
    if tasklist:
        tasklist.pop()

    return {"status": "Kafka polling stopped"}
