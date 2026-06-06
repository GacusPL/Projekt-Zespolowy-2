"use client";

import { useState, useRef, FormEvent, ChangeEvent, useEffect } from "react";
import { UploadCloud, FileText, File, MessageSquare, Send, Loader2, AlertCircle, Moon, Sun } from "lucide-react";

type Message = { id: string; role: "user" | "system"; content: string; isStreaming?: boolean };
type Document = { id: string; name: string; size: string; type: string };

export default function Dashboard() {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [messages, setMessages] = useState<Message[]>([
    { id: "1", role: "system", content: "Cześć! Jestem gotowy do pomocy. Wgraj dokumenty do bazy wiedzy i zadawaj mi pytania." }
  ]);
  const [inputMessage, setInputMessage] = useState("");
  const [isUploading, setIsUploading] = useState(false);
  const [isChatLoading, setIsChatLoading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [chatError, setChatError] = useState<string | null>(null);
  const [isDark, setIsDark] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Initialize dark mode from system preference
  useEffect(() => {
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    setIsDark(prefersDark);
  }, []);

  // Toggle dark class on <html>
  useEffect(() => {
    document.documentElement.classList.toggle("dark", isDark);
  }, [isDark]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleFileUpload = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    setUploadError(null);

    const formData = new FormData();
    formData.append("file", file);

    try {
      const res = await fetch("/api/upload", {
        method: "POST",
        body: formData,
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || "Nie udało się przesłać pliku");
      }

      // Add to documents list
      const ext = file.name.split(".").pop()?.toLowerCase() || "txt";
      let sizeLabel = (file.size / 1024).toFixed(1) + " KB";
      if (file.size > 1024 * 1024) {
        sizeLabel = (file.size / (1024 * 1024)).toFixed(2) + " MB";
      }

      setDocuments(prev => [
        ...prev, 
        { 
          id: Math.random().toString(), 
          name: file.name, 
          size: sizeLabel, 
          type: ext 
        }
      ]);
    } catch (err: any) {
      console.error("Upload error:", err);
      setUploadError(err.message || "Nie udało się przetworzyć dokumentu. Sprawdź, czy Ollama i Supabase działają.");
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const handleSendMessage = async (e: FormEvent) => {
    e.preventDefault();
    if (!inputMessage.trim() || isChatLoading) return;

    const userMsg = inputMessage.trim();
    setInputMessage("");
    setChatError(null);

    const userMsgId = Math.random().toString();
    setMessages(prev => [...prev, { id: userMsgId, role: "user", content: userMsg }]);
    
    // Add placeholder for the AI's streaming response
    const aiMessageId = Math.random().toString();
    setMessages(prev => [...prev, { id: aiMessageId, role: "system", content: "", isStreaming: true }]);

    setIsChatLoading(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: userMsg }),
      });

      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        throw new Error(errorData.error || "Nie udało się połączyć z API czatu");
      }

      if (!res.body) throw new Error("Brak treści odpowiedzi");

      const reader = res.body.getReader();
      const decoder = new TextDecoder("utf-8");

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;

        const textChunk = decoder.decode(value, { stream: true });
        
        setMessages(prev => 
          prev.map(msg => 
            msg.id === aiMessageId 
              ? { ...msg, content: msg.content + textChunk }
              : msg
          )
        );
      }

      // Finalize streaming
      setMessages(prev => 
        prev.map(msg => 
          msg.id === aiMessageId ? { ...msg, isStreaming: false } : msg
        )
      );
      
    } catch (err: any) {
      console.error("Chat error:", err);
      setChatError(err.message || "Nie udało się wygenerować odpowiedzi. Czy Ollama działa?");
      
      // Clean up empty placeholder if generation failed completely
      setMessages(prev => {
        const last = prev[prev.length - 1];
        if (last.id === aiMessageId && !last.content) {
          return prev.slice(0, -1);
        }
        return prev;
      });
    } finally {
      setIsChatLoading(false);
    }
  };

  const triggerFileInput = () => fileInputRef.current?.click();

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-zinc-950 text-slate-900 dark:text-slate-100 font-sans">
      {/* Left Panel - Knowledge Base */}
      <div className="w-1/3 border-r border-slate-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 flex flex-col">
        <div className="p-6 border-b border-slate-200 dark:border-zinc-800">
          <h2 className="text-xl font-semibold flex items-center gap-2">
            <UploadCloud className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            Baza wiedzy
          </h2>
          <p className="text-sm text-slate-500 dark:text-zinc-400 mt-1">Prześlij dokumenty jako kontekst dla AI.</p>
        </div>

        <div className="p-6 flex-1 overflow-y-auto">
          {uploadError && (
            <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg flex items-start gap-2 text-red-600 dark:text-red-400 text-sm">
              <AlertCircle className="w-5 h-5 shrink-0" />
              <p>{uploadError}</p>
            </div>
          )}

          <div 
            onClick={!isUploading ? triggerFileInput : undefined}
            className={`border-2 border-dashed border-slate-300 dark:border-zinc-700 rounded-xl p-8 text-center transition-colors relative
              ${isUploading ? 'opacity-75 cursor-not-allowed bg-slate-50 dark:bg-zinc-800/50' : 'cursor-pointer hover:bg-slate-50 dark:hover:bg-zinc-800/50 group'}`}
          >
            <input 
              type="file" 
              ref={fileInputRef} 
              className="hidden" 
              accept=".pdf,.txt,.md"
              onChange={handleFileUpload}
            />
            
            <div className="mx-auto w-12 h-12 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-full flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              {isUploading ? <Loader2 className="w-6 h-6 animate-spin" /> : <UploadCloud className="w-6 h-6" />}
            </div>
            <p className="font-medium">
              {isUploading ? "Przetwarzanie dokumentu..." : "Kliknij, aby przesłać lub przeciągnij i upuść"}
            </p>
            <p className="text-sm text-slate-500 dark:text-zinc-400 mt-1">PDF, MD, TXT (maks. 10MB)</p>
          </div>

          <div className="mt-8">
            <h3 className="text-sm font-medium text-slate-500 dark:text-zinc-400 uppercase tracking-wider mb-4">
              Przesłane dokumenty ({documents.length})
            </h3>
            {documents.length === 0 ? (
              <p className="text-sm text-slate-400 italic">Brak przesłanych dokumentów.</p>
            ) : (
              <div className="space-y-3">
                {documents.map((doc) => (
                  <div key={doc.id} className="flex items-start gap-3 p-3 rounded-lg border border-slate-200 dark:border-zinc-800 hover:border-blue-300 dark:hover:border-blue-700 transition-colors bg-white dark:bg-zinc-950">
                    <div className="p-2 bg-slate-100 dark:bg-zinc-800 rounded text-slate-600 dark:text-zinc-300">
                      {doc.type === 'pdf' ? <FileText className="w-5 h-5" /> : <File className="w-5 h-5" />}
                    </div>
                    <div>
                      <p className="text-sm font-medium truncate w-48">{doc.name}</p>
                      <p className="text-xs text-slate-500 dark:text-zinc-400">{doc.size}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Right Panel - Chat Interface */}
      <div className="flex-1 flex flex-col bg-slate-50 dark:bg-zinc-950 relative">
        <div className="p-6 border-b border-slate-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-blue-600 dark:text-blue-400" />
              Asystent czatu
            </h2>
            <p className="text-sm text-slate-500 dark:text-zinc-400 mt-1">Zadawaj pytania dotyczące przesłanych dokumentów.</p>
          </div>
          <button 
            onClick={() => setIsDark(!isDark)}
            className="p-2 rounded-lg border border-slate-200 dark:border-zinc-700 hover:bg-slate-100 dark:hover:bg-zinc-800 transition-colors"
            aria-label="Przełącz motyw"
          >
            {isDark ? <Sun className="w-5 h-5 text-yellow-400" /> : <Moon className="w-5 h-5 text-slate-600" />}
          </button>
        </div>

        <div className="flex-1 p-6 overflow-y-auto space-y-6">
          {messages.map((msg) => (
            <div key={msg.id} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[80%] rounded-2xl p-4 ${msg.role === 'user' 
                  ? 'bg-blue-600 text-white rounded-br-sm shadow-sm' 
                  : 'bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-bl-sm'}`}>
                <p className="text-sm leading-relaxed whitespace-pre-wrap">
                  {msg.content}
                  {msg.isStreaming && <span className="inline-block w-1 h-4 ml-1 bg-blue-500 animate-pulse align-middle"></span>}
                </p>
              </div>
            </div>
          ))}
          {chatError && (
             <div className="flex justify-center">
               <div className="px-4 py-2 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 text-sm rounded-full flex items-center gap-2">
                 <AlertCircle className="w-4 h-4" />
                 {chatError}
               </div>
             </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <div className="p-6 bg-white dark:bg-zinc-900 border-t border-slate-200 dark:border-zinc-800">
          <form onSubmit={handleSendMessage} className="relative">
            <input 
              type="text" 
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              disabled={isChatLoading && !messages[messages.length - 1]?.isStreaming}
              placeholder="Zadaj pytanie..." 
              className="w-full pl-4 pr-12 py-4 bg-slate-100 dark:bg-zinc-950 border-none rounded-xl focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 transition-shadow outline-none text-sm disabled:opacity-50"
            />
            <button 
              type="submit"
              disabled={!inputMessage.trim() || (isChatLoading && !messages[messages.length - 1]?.isStreaming)}
              className="absolute right-2 top-1/2 -translate-y-1/2 p-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isChatLoading && !messages[messages.length - 1]?.isStreaming ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
            </button>
          </form>
          <p className="text-xs text-center text-slate-500 dark:text-zinc-500 mt-3">
            AI może popełniać błędy. Weryfikuj ważne informacje.
          </p>
        </div>
      </div>
    </div>
  )
}
