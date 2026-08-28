from pydantic import BaseModel, Field      # Import BaseModel for data validation and Field for constraints

# Define a schema for incoming Kafka messages
class ProduceMessage(BaseModel):           
    message: str = Field(                  # Declare a field named "message" of type string
        min_length=1,                      # Require at least 1 character (prevents empty messages)
        max_length=250                     # Limit message length to 250 characters
    )
