from flask import Flask, render_template, jsonify, request
from src.helper import download_hugging_face_embeddings
from langchain_pinecone import PineconeVectorStore
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from src.prompt import *
from anthropic import Anthropic
from dotenv import load_dotenv
import os

# Initialize Flask app
app = Flask(__name__)

# Load environment variables from .env file
load_dotenv()

# Retrieve Pinecone API key from environment
PINECONE_API_KEY = os.environ.get('PINECONE_API_KEY')
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY  # Ensure it's set for downstream usage

# Initialize HuggingFace embedding model
embeddings = download_hugging_face_embeddings()

# Define Pinecone index name
index_name = "medicalbot"

# Load existing Pinecone index and bind to LangChain
docsearch = PineconeVectorStore.from_existing_index(
    index_name=index_name,
    embedding=embeddings
)

# Convert vector store to retriever
retriever = docsearch.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 3}
)

# Hardcoded Anthropic API key for Claude
client = Anthropic(api_key="")

# Define prompt structure
prompt = ChatPromptTemplate.from_messages([
    ("system", system_prompt),
    ("human", "{input}"),
])

# Claude-compatible wrapper for LangChain's LLM interface
def claude_llm(input_prompt):
    if hasattr(input_prompt, "to_string"):
        input_text = input_prompt.to_string()
    else:
        input_text = str(input_prompt)

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1024,
        messages=[{"role": "user", "content": input_text}]
    )
    return response.content[0].text

# Create document combination chain
question_answer_chain = create_stuff_documents_chain(llm=claude_llm, prompt=prompt)

# Create full RAG chain
rag_chain = create_retrieval_chain(retriever, question_answer_chain)

# Route for chatbot UI
@app.route("/")
def index():
    return render_template('chat.html')

# Route for handling user messages
@app.route("/get", methods=["GET", "POST"])
def chat():
    msg = request.form["msg"]
    print("User input:", msg)
    response = rag_chain.invoke({"input": msg})
    print("Response:", response["answer"])
    return str(response["answer"])

# Run Flask app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080, debug=True)
