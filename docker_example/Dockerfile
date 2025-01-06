FROM langflowai/langflow:latest

# Set the default port to 8080 for Cloud Run compatibility
ENV PORT=8080

# Use /bin/sh to correctly expand environment variables in the CMD
CMD python -m langflow run --host 0.0.0.0 --port $PORT
