# Import helper functions for PDF loading, text chunking, and embedding initialization
from src.helper import load_pdf_file, text_split, download_hugging_face_embeddings

# Import Pinecone's gRPC client for fast vector indexing
from pinecone.grpc import PineconeGRPC as Pinecone

# Import configuration class to specify serverless deployment details
from pinecone import ServerlessSpec

# Import LangChain wrapper to connect document chunks to Pinecone index
from langchain_pinecone import PineconeVectorStore

# Load environment variables from a .env file (e.g., API keys)
from dotenv import load_dotenv

# Access system-level environment variables
import os

# Load variables from .env into the current environment
load_dotenv()

# Retrieve Pinecone API key from environment
PINECONE_API_KEY = os.environ.get('PINECONE_API_KEY')

# Explicitly set the API key in the environment (ensures compatibility with downstream libraries)
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY

# Load all PDF files from the 'Data/' directory using PyPDFLoader
extracted_data = load_pdf_file(data='Data/')

# Split the loaded documents into smaller text chunks for embedding and retrieval
text_chunks = text_split(extracted_data)

# Download and initialize the HuggingFace embedding model ('all-MiniLM-L6-v2')
embeddings = download_hugging_face_embeddings()

# Initialize Pinecone client using the API key
pc = Pinecone(api_key=PINECONE_API_KEY)

# Define the name of the Pinecone index to be created or used
index_name = "medicalbot"

# Create a new Pinecone index with 384-dimensional vectors and cosine similarity
pc.create_index(
    name=index_name,          # Index name
    dimension=384,            # Embedding size from MiniLM model
    metric="cosine",          # Similarity metric for vector search
    spec=ServerlessSpec(      # Serverless deployment configuration
        cloud="aws",          # Cloud provider
        region="us-east-1"    # Deployment region
    )
)

# Convert text chunks into embeddings and upsert them into the Pinecone index
docsearch = PineconeVectorStore.from_documents(
    documents=text_chunks,    # List of chunked documents
    index_name=index_name,    # Target index name
    embedding=embeddings,     # Embedding model used to vectorize the chunks
)
