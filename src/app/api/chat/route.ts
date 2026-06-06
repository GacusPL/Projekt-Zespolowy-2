import { NextRequest, NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

// Next.js config to use Edge runtime for streaming
export const runtime = "edge";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const message = body.message;

    if (!message) {
      return NextResponse.json({ error: "Message is required" }, { status: 400 });
    }

    // 1. Get embedding for the user message using local Ollama instance
    const embeddingResponse = await fetch("http://localhost:11434/api/embeddings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "nomic-embed-text",
        prompt: message,
      }),
    });

    if (!embeddingResponse.ok) {
      throw new Error(`Failed to get embedding: ${embeddingResponse.statusText}`);
    }

    const embeddingData = await embeddingResponse.json();
    const embedding = embeddingData.embedding;

    // 2. Search Supabase for relevant chunks using the vector embedding
    const { data: chunks, error } = await supabase.rpc("match_document_chunks", {
      query_embedding: embedding,
      match_threshold: 0.1, // Lowered threshold to capture more potentially relevant chunks
      match_count: 5,       // Top 5 most relevant fragments for broader context
    });

    if (error) {
      console.error("Supabase match_document_chunks Error:", error);
      return NextResponse.json({ error: "Failed to search knowledge base" }, { status: 500 });
    }

    // 3. Construct prompt with context
    const contextText = (chunks || []).map((chunk: any, i: number) => `[Fragment ${i + 1}]:\n${chunk.content}`).join("\n\n");

    const prompt = `Jesteś pomocnym asystentem, który odpowiada na pytania na podstawie dostarczonych fragmentów dokumentów.
ZAWSZE odpowiadaj po polsku.
Wykorzystaj poniższy kontekst, aby zbudować wyczerpującą odpowiedź. Łącz informacje z wielu fragmentów, jeśli to konieczne.
Jeśli kontekst nie zawiera odpowiednich informacji, powiedz o tym uczciwie.

Kontekst z przesłanych dokumentów:
${contextText}

Pytanie użytkownika: ${message}

Odpowiedź:`;

    // 4. Send request to Ollama's generation endpoint with streaming enabled
    const generateResponse = await fetch("http://localhost:11434/api/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "llama3",
        prompt: prompt,
        stream: true,
      }),
    });

    if (!generateResponse.ok) {
      throw new Error(`Failed to generate LLM response: ${generateResponse.statusText}`);
    }

    if (!generateResponse.body) {
      throw new Error("No response body received from Ollama");
    }

    // 5. Transform the NDJSON stream from Ollama into a plain text stream
    // Ollama streams JSON objects containing {"response": "..."} separated by newlines.
    let buffer = "";
    const transformStream = new TransformStream({
      transform(chunk, controller) {
        // Decode Uint8Array to string
        buffer += new TextDecoder().decode(chunk, { stream: true });
        
        // Split by newline to get individual JSON strings
        const lines = buffer.split("\n");
        // Keep the last potentially incomplete line in the buffer
        buffer = lines.pop() || "";
        
        for (const line of lines) {
          if (!line.trim()) continue;
          try {
            const data = JSON.parse(line);
            if (data.response) {
              // Encode the extracted string back to Uint8Array and enqueue it
              controller.enqueue(new TextEncoder().encode(data.response));
            }
          } catch (e) {
            console.error("Failed to parse Ollama stream line:", line, e);
          }
        }
      },
      flush(controller) {
        if (buffer.trim()) {
          try {
            const data = JSON.parse(buffer);
            if (data.response) {
              controller.enqueue(new TextEncoder().encode(data.response));
            }
          } catch (e) {
            // Ignore incomplete JSON on flush
          }
        }
      }
    });

    // 6. Return the transformed readable stream to the frontend
    const stream = generateResponse.body.pipeThrough(transformStream);

    return new NextResponse(stream, {
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    });

  } catch (error: any) {
    console.error("Chat API Error:", error);
    return NextResponse.json(
      { error: error.message || "Internal Server Error" },
      { status: 500 }
    );
  }
}
