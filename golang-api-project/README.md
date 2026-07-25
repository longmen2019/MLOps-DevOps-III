---

# 📘 README.md  
## Go API Server — Chi Router, Structured Logging, Middleware, Graceful Shutdown

This project is part of my journey learning Go and building production‑style backend services. It implements a clean, modular API server using the Chi router, structured logging with `slog`, versioned routing, authentication middleware, and graceful shutdown.

---

## 🚀 Features

### 🧱 Core Backend Architecture  
- **Chi Router** for fast, idiomatic HTTP routing  
- **Versioned API** under `/api/v1`  
- **Public + Protected Routes**  
- **URL Parameter Parsing** (`/users/{userID}`)  
- **Numeric Validation** for user IDs  

### ⚙️ Middleware Stack  
- **Recoverer** — converts panics into safe 500 responses  
- **StripSlashes** — normalizes trailing slashes  
- **RequestID** — unique ID per request for tracing  
- **Custom Request Logger** using `slog`  
- **Auth Middleware** for protected endpoints  

### 📊 Observability  
- Structured JSON logs  
- Request metrics:  
  - HTTP method  
  - Path  
  - Status code  
  - Bytes written  
  - Duration  
  - Request ID  

### 🛑 Graceful Shutdown  
- Handles `SIGINT` and `SIGTERM`  
- 30‑second timeout for draining connections  
- Clean shutdown logging  

---

## 📡 API Endpoints

### Public  
#### `GET /health`  
Returns service health status.

**Response:**  
```json
{"status": "ok"}
```

---

### Protected  
#### `GET /api/v1/users/{userID}/`  
Requires header:  
```
Authorization: Bearer token
```

Returns the user ID if valid.

**Response:**  
```
User ID: 42
```

**Error Responses:**  
```json
{"error": "missing userID"}
{"error": "invalid userID"}
{"error": "unauthorized"}
```

---

## 🧩 Project Structure

```
.
├── main.go          # Entry point + server setup
├── middleware       # Custom logging + auth
├── handlers         # Health + user handlers
└── README.md        # Project documentation
```

---

## ▶️ Running the Server

```bash
go run main.go
```

Server starts on:

```
http://localhost:8080
```

---

## 🧪 Example Requests

### Health Check  
```powershell
curl http://localhost:8080/health
```

### Authenticated User Request (PowerShell)  
```powershell
curl -Headers @{Authorization="Bearer token"} http://localhost:8080/api/v1/users/42/
```

### Authenticated User Request (Git Bash / WSL)  
```bash
curl -H "Authorization: Bearer token" http://localhost:8080/api/v1/users/42/
```

---

## 🎯 Why This Project Matters

- Demonstrates **real Go backend fundamentals**  
- Shows **clean separation of concerns**  
- Provides a **scalable foundation** for future microservices  
- Reinforces **production‑grade engineering patterns**  
- Great stepping stone for:  
  - JWT authentication  
  - Database integration  
  - Prometheus metrics  
  - Cloud deployment  

