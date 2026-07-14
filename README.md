# Pocket-Page 📱📘

An offline, privacy-first Retrieval-Augmented Generation (RAG) application built entirely in Swift. Pocket-Page allows users to ingest local documents (PDFs, TXT, etc.) and query them using a fully local Large Language Model (LLM) running on-device with hardware acceleration.

---

## 🚀 Key Features

*   **100% On-Device & Offline:** No data leaves the device. Zero API costs, absolute privacy, and works completely offline.
*   **Hardware Accelerated:** Utilizes Apple's Metal Performance Shaders (MPS) via `mlx-swift` / `llama.cpp` wrapper to leverage the Apple Silicon Unified Memory Architecture (UMA) for high-speed inference.
*   **On-Device RAG Pipeline:** Fully integrated pipeline featuring:
    *   Document parsing and chunking.
    *   On-device embedding generation (using lightweight local embedding models).
    *   In-memory vector similarity search (Cosine similarity).
*   **Intuitive SwiftUI UX:** Clean, native iOS/macOS interface designed to easily load documents, track parsing progress, and manage chat sessions.

---

## 🏗️ Architecture & RAG Pipeline

Pocket-Page utilizes a classic local-first RAG pipeline. Because everything runs on Apple Silicon (M-series or A-series chips), the application takes advantage of **Unified Memory** to keep both the embedding process and the LLM generation incredibly efficient.
