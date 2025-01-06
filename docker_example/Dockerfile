FROM langflowai/langflow:latest

# Expose the port that Cloud Run will use
ENV PORT 8080

# Run LangFlow and make it listen on the dynamically provided PORT
CMD ["python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "${PORT}"]
