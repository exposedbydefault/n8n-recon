# n8n-recon

A ready-to-run n8n + PostgreSQL stack for automated IP, domain and URL reconnaissance. Submit a target through a form, and the workflow extracts the domain and enriches it with threat-intelligence sources (AbuseIPDB, VirusTotal, AlienVault OTX, urlscan.io, Cert Spotter) and an LLM (DeepSeek + Gemini).

## Contents

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [API keys](#api-keys)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Security notes](#security-notes)

## Requirements

- Linux host (tested on Kali) with `sudo`
- Docker Engine and the Docker Compose v2 plugin
- API keys for the services you want to use (see [API keys](#api-keys))

Install Docker:

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
```

Check that Compose v2 is available (the commands below use `docker compose`, not `docker-compose`):

```bash
sudo docker compose version
```

If that fails, install Compose v2 from your distro (`docker-compose-v2` or `docker-compose-plugin`) or from Docker's official repository.

## Quick start

**1. Clone the repo and create your `.env`**

```bash
cd n8n-recon
cp .env.example .env
nano .env        # set passwords, see Configuration below
```

**2. Create the Docker volumes** (they are declared `external`, so Compose won't create them)

```bash
sudo docker volume create n8n_data
sudo docker volume create postgres_data
```

**3. Build and start**

```bash
sudo docker compose up -d --build
sudo docker compose ps
```

Wait until both containers show `Up`. To follow the logs: `sudo docker compose logs -f`.

**4. Open n8n and create the owner account**

Go to <http://localhost:5678> and complete the setup screen.

**5. Import the credential template**

```bash
sudo docker compose cp creds.blank.json n8n:/home/node/.n8n/creds.blank.json
sudo docker compose exec n8n n8n import:credentials --input=/home/node/.n8n/creds.blank.json
sudo docker compose exec n8n rm /home/node/.n8n/creds.blank.json
```

**6. Add your secrets**

The template contains placeholders (`YOUR-KEY-HERE`), which n8n stores as if they were real keys. Open **Credentials** in n8n, open each entry and replace the placeholder with your real key. See [API keys](#api-keys).

**7. Import the workflow**

**Workflows → Create workflow → ⋯ → Import from file →** select `n8n-schema.json`.

Open the workflow, check that each node shows its credential, then run a test.

## API keys

| Credential name                 | Service                                                | Notes                                                          |
| ------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------- |
| AbuseIPDB                       | [abuseipdb.com](https://www.abuseipdb.com)             | Header `Key`                                                   |
| VirusTotal                      | [virustotal.com](https://www.virustotal.com)           | Header `x-apikey`                                              |
| OTX                             | [otx.alienvault.com](https://otx.alienvault.com)       | Header `X-OTX-API-KEY`                                         |
| URLScan.io                      | [urlscan.io](https://urlscan.io)                       | Header `API-Key`                                               |
| DeepSeek account                | [platform.deepseek.com](https://platform.deepseek.com) | API key                                                        |
| Google Gemini(PaLM) Api account | [aistudio.google.com](https://aistudio.google.com)     | API key                                                        |
| Postgres account                | local                                                  | Host `postgres`, database `n8n`, user and password from `.env` |

Cert Spotter works without a key (free tier: 100 queries/hour).

## Updating

```bash
git pull
sudo docker compose up -d --build
```

The image is built from `n8nio/n8n:nightly`, which is a development build and can break between pulls. For stable use, pin a version tag in the `Dockerfile`.

## Troubleshooting

**Credential import fails because there is no owner.**
Finish the setup screen at <http://localhost:5678> first, then rerun the import.

**Workflow nodes show "credential not found".**
The workflow's credential IDs must match the template's. Import `creds.blank.json` before the workflow, and don't recreate the credentials by hand (that gives them new IDs).

## Uninstall

Stop and remove the containers:

```bash
sudo docker compose down
```

`down -v` does **not** remove the `n8n_data` and `postgres_data` volumes, because they are declared `external`. To delete all data permanently (workflows, credentials, database), remove them yourself:

```bash
sudo docker volume rm n8n_data postgres_data
```

This cannot be undone. Export your workflows first if you want to keep them.

## Security notes

- Never commit `.env` or any decrypted credential export.
- Don't expose port 5678 to the internet without HTTPS and authentication. Put n8n behind a reverse proxy (Caddy, Nginx, Traefik) if it is reachable from outside.
- Don't publish Postgres to the host. The `ports:` mapping on the `postgres` service isn't needed, because n8n reaches it over the Compose network.
