# Import PDF loader classes from LangChain to handle document ingestion
from langchain.document_loaders import PyPDFLoader, DirectoryLoader

# Import a text splitter that recursively breaks documents into manageable chunks
from langchain.text_splitter import RecursiveCharacterTextSplitter

# Import HuggingFace embedding model wrapper for vector representation of text
from langchain.embeddings import HuggingFaceEmbeddings


# Function to extract data from all PDF files in a given directory
def load_pdf_file(data):
    # Initialize a DirectoryLoader to scan the specified folder for PDF files
    # 'glob="*.pdf"' filters for only PDF files
    # 'loader_cls=PyPDFLoader' specifies that each PDF should be loaded using PyPDFLoader
    loader = DirectoryLoader(data,
                             glob="*.pdf",
                             loader_cls=PyPDFLoader)

    # Load all matching PDF documents into a list of Document objects
    documents = loader.load()

    # Return the list of loaded documents
    return documents


# Function to split extracted documents into smaller text chunks for embedding or retrieval
def text_split(extracted_data):
    # Initialize a text splitter that breaks documents into chunks of 500 characters
    # with a 20-character overlap between chunks to preserve context
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=20)

    # Apply the splitter to the extracted documents to produce a list of text chunks
    text_chunks = text_splitter.split_documents(extracted_data)

    # Return the list of text chunks
    return text_chunks


# Function to download and initialize a HuggingFace embedding model
def download_hugging_face_embeddings():
    # Load the 'all-MiniLM-L6-v2' model from HuggingFace, which produces 384-dimensional embeddings
    embeddings = HuggingFaceEmbeddings(model_name='sentence-transformers/all-MiniLM-L6-v2')

    # Return the initialized embedding model
    return embeddings
