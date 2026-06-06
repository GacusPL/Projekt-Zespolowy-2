import PDFParser from "pdf2json";

/**
 * Extracts text from an uploaded file (PDF, TXT, or MD).
 * @param file The uploaded File object.
 * @returns The extracted string content.
 */
export async function extractTextFromFile(file: File): Promise<string> {
  const buffer = Buffer.from(await file.arrayBuffer());
  const ext = file.name.split(".").pop()?.toLowerCase();

  if (ext === "pdf") {
    return new Promise((resolve, reject) => {
      const pdfParser = new PDFParser(null, true); // true = flag to extract raw text
      pdfParser.on("pdfParser_dataError", (errData: any) => reject(new Error(errData.parserError)));
      pdfParser.on("pdfParser_dataReady", () => {
        resolve(pdfParser.getRawTextContent());
      });
      pdfParser.parseBuffer(buffer);
    });
  } else if (ext === "md" || ext === "txt") {
    return buffer.toString("utf-8");
  } else {
    throw new Error("Unsupported file type. Use PDF, MD, or TXT.");
  }
}

/**
 * Splits extracted text into semantic chunks.
 * @param text The full text content.
 * @param chunkSize The approximate number of words per chunk.
 * @param overlap The number of overlapping words between consecutive chunks.
 * @returns An array of string chunks.
 */
export function chunkText(text: string, chunkSize = 500, overlap = 50): string[] {
  // Normalize whitespace (handles newlines, tabs, and multiple spaces)
  const normalizedText = text.replace(/\s+/g, " ").trim();
  const words = normalizedText.split(" ");
  const chunks: string[] = [];
  
  if (words.length === 0 || words[0] === "") {
    return chunks;
  }

  let i = 0;
  while (i < words.length) {
    const chunk = words.slice(i, i + chunkSize).join(" ");
    chunks.push(chunk);
    
    // Advance index by (chunkSize - overlap), ensuring we always move forward
    i += Math.max(1, chunkSize - overlap);
  }
  
  return chunks;
}

/**
 * Fetches the vector embedding for a given text chunk from a local Ollama instance.
 * @param text The text chunk to embed.
 * @returns An array of numbers representing the embedding.
 */
export async function getEmbedding(text: string): Promise<number[]> {
  const response = await fetch("http://localhost:11434/api/embeddings", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "nomic-embed-text",
      prompt: text,
    }),
  });

  if (!response.ok) {
    throw new Error(`Ollama embedding failed: ${response.statusText}`);
  }

  const data = await response.json();
  return data.embedding;
}
