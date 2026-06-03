#!/usr/bin/env bash
set -euo pipefail

# Simple helper to run the Flask proxy app
# Usage: ./run_app.sh

VENV=.venv
if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV"
fi

source "$VENV/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt

export FLASK_ENV=production
python3 app.py
