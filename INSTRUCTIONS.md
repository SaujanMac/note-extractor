# 🧠 Phi-3 + llama.cpp IMS POC Setup Guide

This guide walks through setting up a **lightweight local LLM (Phi-3 Mini)** using **llama.cpp**, and building a simple **browser-based IMS extraction tool**.

---

# ⚡ 1. Install llama.cpp

```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make -j
```

---

# 📦 2. Download Phi-3 (GGUF format)

Go to Hugging Face:

👉 https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf

Download a **4-bit quantized model** (recommended):

```bash
mkdir -p models
cd models

wget https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf
```

> ⚠️ Model names may change. Always check available files on the page.

---

# 🚀 3. Run llama.cpp server

From root of `llama.cpp`:

```bash
./build/bin/llama-server \
  -m models/Phi-3-mini-4k-instruct-q4.gguf \
  -c 1024 \
  --host 0.0.0.0
```

Server will run at:

```
http://127.0.0.1:8080
```

---

# 🧪 4. Test API

```bash
curl http://127.0.0.1:8080/completion \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Hello",
    "n_predict": 20
  }'
```

---

# 🖥️ 5. Create Frontend (IMS POC)

Create `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>IMS Phi-3 POC</title>
</head>
<body>

<input id="input" value="5kg rice from Ram Dai credit">
<button onclick="run()">Extract</button>

<pre id="output"></pre>

<script>
async function run() {
  const text = document.getElementById("input").value;
  const output = document.getElementById("output");

  output.innerText = "Processing...";

  const prompt = `<|system|>
You are an IMS extraction engine.

Return ONLY ONE valid JSON object.

Rules:
- No explanation
- No extra text
- No continuation
- Output must be strictly JSON

Schema:
{
  "item": string|null,
  "quantity": number|null,
  "unit": string|null,
  "customer": string|null,
  "type": "credit"|"cash"|null
}

Input:
${text}
`;

  const res = await fetch("http://127.0.0.1:8080/completion", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      prompt,
      temperature: 0.0,
      top_p: 0.3,
      n_predict: 80,
      stop: ["Input:", "\n\n"]
    })
  });

  const data = await res.json();
  const content = data.content || "";

  let parsed;

  try {
    parsed = JSON.parse(content);
  } catch {
    const match = content.match(/\{[\s\S]*\}/);
    parsed = match ? JSON.parse(match[0]) : { raw: content };
  }

  output.innerText = JSON.stringify(parsed, null, 2);
}
</script>

</body>
</html>
```

---

# 🌐 6. Run in Browser

Use **VS Code Live Server** or open manually:

```
http://127.0.0.1:5500
```

---

# 🧠 Important Concepts

## ❌ Do NOT use `<|assistant|>`

Causes:

* multi-response outputs
* "Now process..." continuation
* unstable JSON

## ✅ Use instruction-only prompts

Better for:

* extraction
* deterministic output
* structured data

---

# ⚡ Recommended Settings

```json
{
  "temperature": 0.0,
  "top_p": 0.3,
  "n_predict": 80,
  "stop": ["Input:", "\n\n"]
}
```

---

# 🔥 Optional Improvements

## 1. Grammar-based JSON (best)

Use llama.cpp grammar to enforce strict JSON.

## 2. Node proxy (fix CORS)

Browser → Node → llama.cpp

## 3. Streaming UI

Show tokens in real time.

## 4. Batch processing

Upload multiple sticky notes.

---

# 🚀 Final Result

You now have:

* 🧠 Local LLM (Phi-3 Mini)
* ⚡ <1GB RAM usage (4-bit)
* 🌐 Browser UI (no backend needed)
* 📦 JSON extraction for IMS

---

# 💡 Example Input

```
10 cans of beans from John Doe cash
```

## Output

```json
{
  "item": "beans",
  "quantity": 10,
  "unit": "cans",
  "customer": "John Doe",
  "type": "cash"
}
```

---

# 🏁 Summary

| Component | Tool                |
| --------- | ------------------- |
| Model     | Phi-3 Mini          |
| Runtime   | llama.cpp           |
| API       | llama-server        |
| UI        | HTML + JS           |
| Editor    | VS Code Live Server |

---

# 🧭 Next Steps

* Build full IMS dashboard
* Store data (SQLite / Laravel)
* Add authentication
* Sync to cloud / Fediverse (your Typr vision 👀)

---

End of guide.
