# Makefile - Dev commands for Fake API using uv

# 🚀 Run the FastAPI server locally with auto-reload
run:
	uvicorn app.app:app --reload

# 🧪 Run all unit tests with pytest
test:
	pytest

# 📦 Install dependencies via uv and install project locally
install:
	uv venv && uv pip install ../shared_module
	uv venv && uv pip install .

# 🧹 Delete all compiled Python files (.pyc)
clean-pyc:
	find . -name "*.pyc" -delete

# 🔁 Install dependencies and start the server
all: install run
