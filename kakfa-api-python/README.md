# 📘 **FastAPI Kafka Microservices — Producer & Consumer**

This project demonstrates a lightweight microservice architecture using **FastAPI** and **Kafka**, featuring:

- A **FastAPI Producer** that sends JSON messages to Kafka  
- A **FastAPI Consumer** that polls Kafka asynchronously  
- A **sanitized POST `/trigger` endpoint** to safely start the consumer  
- A **Docker Compose Kafka stack**  
- Clean separation of services for real microservice behavior  

---

## 🚀 **Project Structure**

```
fastapi-KAFKA/
│
├── fastapi-producer/
│   ├── main.py
│   ├── kafka_producer.py
│   ├── producer_schema.py
│   └── requirements.txt
│
├── fastapi-consumer/
│   ├── main.py
│   └── requirements.txt
│
├── docker-compose.yml
│
└── venv/
```

---

## 🧩 **Components Overview**

### **1. FastAPI Producer**
- Exposes a POST endpoint:  
  ```
  POST /produce/message
  ```
- Accepts a JSON payload:
  ```json
  {
    "message": "Hello World!"
  }
  ```
- Sends the message to Kafka as JSON:
  ```json
  {"message": "Hello World!"}
  ```

### **2. FastAPI Consumer**
- Exposes:
  ```
  POST /trigger
  GET /stop-trigger
  ```
- `/trigger` starts an async Kafka polling task  
- `/stop-trigger` stops the consumer  
- Includes **topic sanitization** to prevent Kafka errors:
  - Spaces → replaced with `-`
  - Invalid characters → removed
  - Lowercased
  - Fallback to `fastapi-topic` if empty

### **3. Kafka (via Docker Compose)**
- Runs:
  - Zookeeper  
  - Kafka broker  
- Exposes port `29092` for local development

---

## 🔧 **Running the Project**

### **1. Start Kafka**
From the project root:

```bash
docker compose up -d
```

Verify Kafka is running:

```bash
nc -zv localhost 29092
```

---

### **2. Start Producer**

```bash
cd fastapi-producer
source venv/bin/activate
fastapi dev main.py --port 8002
```

Producer docs:

```
http://127.0.0.1:8002/docs
```

---

### **3. Start Consumer**

```bash
cd fastapi-consumer
source venv/bin/activate
fastapi dev main.py --port 8001
```

Consumer docs:

```
http://127.0.0.1:8001/docs
```

---

## 📨 **Sending Messages**

### **Producer**
Use Swagger UI:

```
POST /produce/message
```

Example body:

```json
{
  "message": "Hello World!"
}
```

---

## 🔄 **Starting the Consumer Poller**

### **Consumer**
Use Swagger UI:

```
POST /trigger
```

You will see a text box:

```
topic: fastapi-topic
```

You can enter any text — the consumer sanitizes it:

| Input           | Sanitized Topic |
|-----------------|------------------|
| Hello World     | hello-world      |
| My Topic!!!     | my-topic         |
| 🔥🔥🔥           | fastapi-topic    |

---

## 🛑 **Stopping the Consumer**

```
GET /stop-trigger
```

This stops the background polling task.

---

## 📡 **Consumer Output Example**

Terminal logs:

```
Trying to Poll again
Received the message Hello World! from the topic fastapi-topic
Trying to Poll again
Received the message Hello World! from the topic fastapi-topic
```

---

## 🛠 **Key Features**

- ✔ FastAPI microservice architecture  
- ✔ Kafka producer + consumer  
- ✔ Async consumer polling  
- ✔ Topic sanitization to prevent Kafka crashes  
- ✔ Background tasks using `asyncio.create_task`  
- ✔ Clean JSON serialization/deserialization  
- ✔ Swagger UI support for both services  

---

## 📦 **Dependencies**

### Producer
```
fastapi[standard]
confluent-kafka
```

### Consumer
```
fastapi[standard]
kafka-python
```

### Kafka Stack
```
docker-compose
zookeeper
kafka
```

---

## 🧭 **Next Steps (Optional Enhancements)**

- Add `/status` endpoint  
- Add `/messages` endpoint to return consumed messages  
- Add Kafdrop UI for Kafka topic inspection  
- Add logging middleware  
- Add Kubernetes manifests (AKS/EKS)  
- Add Terraform automation  

---