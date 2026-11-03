FROM ghcr.io/omnigent-ai/omnigent-server:v0.20.0

# The published image has no `s3` extra. Same version range as the extra.
RUN python -m pip install --no-cache-dir 'boto3>=1.30,<2' 'botocore>=1.30,<2' \
 && python -c "import boto3"

# Anchors the server's data dir at /data, as the upstream docker-compose does.
# Without it the server looks for ~/.omnigent/config.yaml. No file is written
# at this path.
ENV OMNIGENT_ADMIN_CREDENTIALS_PATH=/data/admin-credentials

COPY config.yaml /data/config.yaml
