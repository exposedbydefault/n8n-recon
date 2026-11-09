FROM n8nio/n8n:nightly

USER root

# uv binary, copied from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Install Python in a fixed location so the node user can use it
ENV UV_PYTHON_INSTALL_DIR=/opt/python
RUN uv venv --python 3.14 /opt/venv && \
    uv pip install --python /opt/venv/bin/python pymongo requests

ENV PATH="/opt/venv/bin:$PATH"

RUN mkdir -p /home/node/.cache && chown -R node:node /home/node/.cache

USER node