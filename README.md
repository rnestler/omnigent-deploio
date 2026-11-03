# omnigent-deploio
Host omnigent on deplo.io

Builds the Omnigent server image with S3 support and a baked-in `config.yaml`.
Deploio builds it from the `Dockerfile` on `main`. To upgrade, change the image
tag in the `Dockerfile`.

This repo is public, so never commit secrets. Set them as env vars in Cockpit.

## Deploy

Everything runs in its own Deploio project, so every command passes `-p`.

```bash
PROJECT=$DEPLOIO_ORG-omnigent
nctl create project "$PROJECT" --wait
nctl create postgresdatabase omnigent -p "$PROJECT" --location=nine-es34 --wait
nctl create bucketuser omnigent -p "$PROJECT" --location=nine-es34 --wait
nctl create bucket omnigent -p "$PROJECT" --location=nine-es34 --permissions=writer=omnigent --wait
nctl create app omnigent -p "$PROJECT" \
  --git-url=https://github.com/rnestler/omnigent-deploio.git \
  --dockerfile --port=8000 --size=standard-2 --replicas=1
```

The first release fails until the env vars below are set. After setting or
changing them, run `nctl update app omnigent -p "$PROJECT" --retry-release`.

## Required env vars

- `DATABASE_URL`
- `OMNIGENT_AUTH_ENABLED` (`1`)
- `OMNIGENT_ACCOUNTS_BASE_URL` (`https://<app host>`)
- `OMNIGENT_ACCOUNTS_COOKIE_SECRET`
- `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD`
- `OMNIGENT_ARTIFACT_URI` (`s3://<bucket>/omnigent`)
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION` (`us-east-1`)
- `AWS_ENDPOINT_URL`
