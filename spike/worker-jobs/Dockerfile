# Throwaway image for the worker job test. Holds a listener and probe.sh.
FROM python:3.13-slim
COPY probe.sh /usr/local/bin/probe.sh
RUN chmod 755 /usr/local/bin/probe.sh
WORKDIR /srv
CMD ["sh", "-c", "exec python -m http.server \"${PORT:-8080}\""]
