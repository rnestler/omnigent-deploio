# Throwaway image for spike/worker-jobs/run.sh. Holds nothing but a listener.
FROM python:3.13-slim
CMD ["sh", "-c", "exec python -m http.server \"${PORT:-8080}\""]
