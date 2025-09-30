

## 🩺 Medical Chatbot with Claude 3 + LangChain + Pinecone

This project is an end-to-end intelligent chatbot designed to answer medical questions using a Retrieval-Augmented Generation (RAG) pipeline. It leverages:

- **Claude 3 Sonnet** via Anthropic SDK for natural language generation
- **LangChain** for document retrieval and orchestration
- **Pinecone** for vector-based semantic search
- **Flask** for the web interface
- **HuggingFace embeddings** for document chunking and indexing

---

## 🚀 Features

- Upload and index medical PDFs
- Ask natural language questions via a web UI
- Retrieves relevant context and generates concise answers
- Clean Bootstrap-powered chat interface
- Modular ingestion and retrieval pipeline

---

## 🧱 Project Structure

```
├── src/
│   ├── helper.py           # PDF loading, chunking, embedding setup
│   ├── prompt.py           # System prompt for Claude
├── static/
│   ├── style.css           # Custom chat UI styling
├── templates/
│   ├── chat.html           # Frontend HTML template
├── app.py                  # Flask app with Claude integration
├── store-index.py          # Script to ingest and index PDFs
├── Data/                   # Folder for medical PDFs
├── .env                    # Stores Pinecone API key
```

---

## ⚙️ Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/medical-chatbot.git
cd medical-chatbot
```

### 2. Create and Activate Environment

```bash
conda create -n medibot python=3.10
conda activate medibot
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

> Make sure to include `langchain`, `anthropic`, `pinecone-client`, `flask`, `huggingface-hub`, etc.

### 4. Set Environment Variables

Create a `.env` file with:

```
PINECONE_API_KEY=your-pinecone-key
```

Claude API key is hardcoded in `app.py`. You can replace it with your own.

---

## 📚 Index Your PDFs

Place your medical PDFs in the `Data/` folder, then run:

```bash
python store-index.py
```

This will:
- Load and chunk the PDFs
- Embed them using HuggingFace
- Store them in your Pinecone index

---

## 💬 Run the Chatbot

```bash
python app.py
```

Visit [http://localhost:8080](http://localhost:8080) to start chatting.

---

## 🧠 How It Works

1. **User asks a question**
2. **Retriever fetches top 3 relevant chunks from Pinecone**
3. **Claude receives the context + question**
4. **Claude generates a concise answer**
5. **Frontend displays the response**

---

## 🛠️ Customization

- To change the system prompt, edit `src/prompt.py`
- To switch LLMs (e.g., OpenAI, Cohere), update `app.py`
- To adjust chunk size or overlap, modify `helper.py`

---

## 📌 Credits

Built with:
- [LangChain](https://www.langchain.com/)
- [Anthropic Claude](https://www.anthropic.com/)
- [Pinecone](https://www.pinecone.io/)
- [HuggingFace](https://huggingface.co/)
- [Bootstrap](https://getbootstrap.com/)
