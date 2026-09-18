#!/bin/sh

set -e

# Harnesses
curl -fsSL https://opencode.ai/install | bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Local AI runtime (Ollama)
yay -S --needed --noconfirm ollama

OLLAMA_BG_PID=""

start_ollama() {
    if [ -f "$HOME/.config/systemd/user/ollama.service" ]; then
        echo "Starting Ollama user service..."
        systemctl --user daemon-reload
        systemctl --user enable --now ollama.service
    else
        echo "No user service found at ~/.config/systemd/user/ollama.service"
        echo "Starting temporary Ollama server for model pull..."
        ollama serve >/tmp/ollama-install.log 2>&1 &
        OLLAMA_BG_PID=$!
    fi
}

wait_for_ollama() {
    echo "Waiting for Ollama API on http://127.0.0.1:11434 ..."
    i=0
    until curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; do
        i=$((i + 1))
        if [ "$i" -ge 30 ]; then
            echo "Timed out waiting for Ollama server"
            exit 1
        fi
        sleep 1
    done
}

start_ollama
wait_for_ollama

echo "Pulling qwen2.5-coder:3b ..."
ollama pull qwen2.5-coder:3b

if [ -n "$OLLAMA_BG_PID" ]; then
    echo "Stopping temporary Ollama server (PID $OLLAMA_BG_PID)"
    kill "$OLLAMA_BG_PID" || true
fi

