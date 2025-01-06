FROM langflowai/langflow:latest

# Run LangFlow and make it listen on the dynamically provided PORT
CMD ["python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "${PORT}"]
