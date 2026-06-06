export const runtime = 'nodejs';

import { NextRequest, NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";
import { extractTextFromFile, chunkText, getEmbedding } from "@/lib/document-processing";

export async function POST(req: NextRequest) {
  try {
    // 1. Get the FormData and extract the file
    const formData = await req.formData();
    const file = formData.get("file") as File | null;

    if (!file) {
      return NextResponse.json(
        { error: "No file provided in the request payload." },
        { status: 400 }
      );
    }

    // 2. Extract text using the modular utility
    let extractedText: string;
    try {
      extractedText = await extractTextFromFile(file);
    } catch (err: any) {
      return NextResponse.json(
        { error: err.message || "Failed to extract text from file." },
        { status: 400 }
      );
    }

    if (!extractedText.trim()) {
      return NextResponse.json(
        { error: "Extracted text is empty." },
        { status: 400 }
      );
    }

    // 3. Insert document metadata into Supabase
    const { data: document, error: docError } = await supabase
      .from("documents")
      .insert({ filename: file.name })
      .select("id")
      .single();

    if (docError) {
      console.error("Supabase Document Insert Error:", docError);
      return NextResponse.json(
        { error: "Failed to create document record in database." },
        { status: 500 }
      );
    }

    const documentId = document.id;

    // 4. Split text into semantic chunks (~500 words with 50 words overlap)
    const chunks = chunkText(extractedText, 500, 50);

    // 5. Fetch embeddings for each chunk
    const chunkInserts = [];
    for (const content of chunks) {
      if (!content.trim()) continue;

      try {
        const embedding = await getEmbedding(content);
        chunkInserts.push({
          document_id: documentId,
          content,
          embedding,
        });
      } catch (embError) {
        console.error("Embedding generation error for chunk:", embError);
        // Depending on requirements, we can continue or fail entirely.
        // We'll throw to ensure complete consistency.
        throw new Error("Failed to generate embeddings from local Ollama instance.");
      }
    }

    // 6. Insert chunks and embeddings into Supabase
    if (chunkInserts.length > 0) {
      const { error: chunksError } = await supabase
        .from("document_chunks")
        .insert(chunkInserts);

      if (chunksError) {
        console.error("Supabase Chunks Insert Error:", chunksError);
        return NextResponse.json(
          { error: "Failed to save chunks and embeddings to database." },
          { status: 500 }
        );
      }
    }

    return NextResponse.json(
      {
        success: true,
        message: "Document successfully processed.",
        details: {
          documentId,
          chunksProcessed: chunkInserts.length,
        },
      },
      { status: 200 }
    );
  } catch (error: any) {
    console.error("Unhandled Upload Error:", error);
    return NextResponse.json(
      { error: error.message || "Internal Server Error" },
      { status: 500 }
    );
  }
}
