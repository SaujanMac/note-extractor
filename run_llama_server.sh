#!/usr/bin/env bash
set -euo pipefail

# Helper to run llama-server. Auto-detects common locations for the binary
# and model so the script can be run from this project root without args.
# You can still override with env vars or positional args:
#   LLAMA_SERVER_BIN=/full/path/to/llama-server \ 
#     LLAMA_MODEL=/full/path/to/model.gguf ./run_llama_server.sh [port]
# Or provide explicit bin and model as positional args:
#   ./run_llama_server.sh /path/to/llama-server /path/to/model.gguf 8080

PORT_DEFAULT=8080

# Candidate binary locations (searched in order)
HOME_DIR="${HOME:-/root}"
CANDIDATE_BINS=(
  ./build/bin/llama-server
  ../llama.cpp/build/bin/llama-server
  $HOME_DIR/llama.cpp/build/bin/llama-server
  $HOME_DIR/llama.cpp/build/llama-server
  /usr/local/bin/llama-server
  /usr/bin/llama-server
)

select_bin() {
  # env override
  if [ -n "${LLAMA_SERVER_BIN:-}" ]; then
    echo "$LLAMA_SERVER_BIN"
    return
  fi

  # explicit first arg if executable
  if [ "$#" -ge 1 ] && [ -x "$1" ] && [ ! -d "$1" ]; then
    echo "$1"
    return
  fi

  for p in "${CANDIDATE_BINS[@]}"; do
    if [ -x "$p" ]; then
      echo "$p"
      return
    fi
  done

  # fallback: try to find in $HOME
  found=$(find "$HOME_DIR" -maxdepth 3 -type f -path "*/build/bin/llama-server" 2>/dev/null | head -n1 || true)
  if [ -n "$found" ] && [ -x "$found" ]; then
    echo "$found"
    return
  fi

  # lastly, check PATH
  if command -v llama-server >/dev/null 2>&1; then
    command -v llama-server
    return
  fi

  # nothing
  echo "" 
}

select_model() {
  # env override
  if [ -n "${LLAMA_MODEL:-}" ]; then
    echo "$LLAMA_MODEL"
    return
  fi

  # explicit second arg
  if [ "$#" -ge 2 ] && [ -f "$2" ]; then
    echo "$2"
    return
  fi

  # look for common names in local models folder
  candidates=(
    ./models/Phi-3-mini-4k-instruct-q4.gguf
    ./models/Phi-3-mini-4k-instruct-Q4_K_M.gguf
    ./models/Phi-3-mini-4k-instruct*.gguf
    ../llama.cpp/models/Phi-3-mini-4k-instruct*.gguf
    $HOME_DIR/llama.cpp/models/Phi-3-mini-4k-instruct*.gguf
  )

  for pat in "${candidates[@]}"; do
    for f in $pat; do
      if [ -f "$f" ]; then
        echo "$f"
        return
      fi
    done
  done

  # fallback: first .gguf under common model dirs
  for dir in ./models ../llama.cpp/models $HOME_DIR/llama.cpp/models $HOME_DIR/.cache/llama/models $HOME_DIR/.local/share/llama/models; do
    if [ -d "$dir" ]; then
      found=$(find "$dir" -maxdepth 2 -type f -name "*.gguf" 2>/dev/null | grep -i "phi\|Phi\|phi-3\|Phi-3" | head -n1 || true)
      if [ -z "$found" ]; then
        found=$(find "$dir" -maxdepth 2 -type f -name "*.gguf" 2>/dev/null | head -n1 || true)
      fi
      if [ -n "$found" ]; then
        echo "$found"
        return
      fi
    fi
  done

  # none found
  echo ""
}

# pick binary and model
BIN=$(select_bin "$@")
MODEL=$(select_model "$@")

# If user provided only one positional arg which was not an executable, treat as model
if [ -z "$MODEL" ] && [ "$#" -ge 1 ] && [ -f "$1" ]; then
  MODEL="$1"
fi

PORT=${3:-${2:-$PORT_DEFAULT}}

if [ -z "$BIN" ]; then
  echo "Error: llama-server binary not found."
  echo "Searched common locations. To override, set LLAMA_SERVER_BIN or pass the binary path as first arg."
  exit 2
fi

if [ -z "$MODEL" ]; then
  echo "Error: no .gguf model file found."
  echo "Place a model under ./models or in ~/llama.cpp/models, or set LLAMA_MODEL or pass model path as arg."
  exit 3
fi

echo "Starting llama-server binary=$BIN model=$MODEL port=$PORT"
"$BIN" -m "$MODEL" -c 1024 --host 0.0.0.0 --port "$PORT"
