# omnigent-deploio
Host omnigent on deplo.io

Builds the Omnigent server image with S3 support and a baked-in `config.yaml`.
Deploio builds it from the `Dockerfile` on `main`. To upgrade, change the image
tag in the `Dockerfile`.

This repo is public, so never commit secrets. They are set as env vars on the
app.

## Deploy

```bash
nctl auth login
DEPLOIO_ORG=<org> ./deploy.sh
```

The script creates the `<org>-omnigent` project, the database, the bucket and
the app. It fetches the credentials with nctl and generates the cookie secret,
and asks only for the admin password and the app host. Secrets are never
printed. They do appear in the local process list while nctl runs.

Later commands need the project, for example
`nctl logs app omnigent -p <org>-omnigent -f`. After changing env vars, run
`nctl update app omnigent -p <org>-omnigent --retry-release`.

The app runs on the `mini` size (512 MiB). If it runs out of memory, resize it with
`nctl update app omnigent -p <org>-omnigent --size=standard-1`.

## Env vars set by the script

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
