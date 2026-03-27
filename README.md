# Intro to APIs and Docker

This repo contains a [notebook](01-intro-to-json.ipynb) explaining how to work with JSON data, followed by a few Markdown lessons that walk through building a simple FastAPI app and containerizing it with Docker.

1. Small introduction to Docker and how to spin up a local database with it. [Intro to docker](02-intro-to-docker.md)
2. Introduction to FastAPI and how to create a simple API. [Intro to FastAPI](03-intro-to-fastapi.md)
3. Introduction to Docker and how to containerize your API. [Intro to Docker](04-intro-to-docker-part2.md)
4. Introduction to Docker Compose and how to spin up your API and a local database with it. [Intro to Docker Compose](05-intro-to-docker-compose.md)

## Mermaid Diagrams

This repository contains Mermaid diagrams. If you want them to render in VS Code, we recommend installing the `Markdown Preview Mermaid Support` extension:

- [Install in VS Code](vscode:extension/bierner.markdown-mermaid)
- [View on Marketplace](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid)

## Environment

You can find the requirements file in the **/service** directory. Use this file to create a new environment for this task.

### **`macOS`**

```BASH
pyenv local 3.11.3
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r service/requirements.txt
pip install jupyter
```

#### **`Windows`**

For `PowerShell` CLI :

```PowerShell
pyenv local 3.11.3
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r service/requirements.txt
pip install jupyter
```

For `Git-Bash` CLI :

```text
pyenv local 3.11.3
python -m venv .venv
source .venv/Scripts/activate
pip install --upgrade pip
pip install -r service/requirements.txt
pip install jupyter
```

### Setup

- You need to install **Docker** for this task. Please **install the Desktop version** (for MacOS with M1/M2 chips there is no alternative). You can find the installation instructions [**here**](https://docs.docker.com/get-docker/).

- Installing `psql` is helpful if you want to connect to PostgreSQL from your machine, but the Docker lessons also include a `docker exec ... psql` fallback if you prefer not to install it locally.

#### **`macOS`**

```sh
brew install postgresql@17

# To start services
brew services start postgresql@17

# To stop
brew services stop postgresql@17
```

In case `psql` doesn't work:

```sh
brew install libpq
brew link --force libpq
```

#### **`Windows`**

Please follow the [installation instructions](https://www.w3schools.com/postgresql/postgresql_install.php).

### Diagram

When you are done with the exercise this is the structure you will have created.

```mermaid
graph TD
    %% --- Subgraphs for Organization ---
    subgraph Client [Client Environment]
        C[Web Browser or cURL]
    end

    subgraph Host [Docker Host / Local Machine]
        direction LR
        S[Docker Socket]
        N(User-Defined Bridge Network)

        subgraph FastAPI_Service [FastAPI Service]
            DAPP(Docker Container: fastapi)
            DAPP_FAS(FastAPI Application)
        end

        subgraph Database_Service [Database Service]
            DDB(Docker Container: postgres)
            DDB_PG(PostgreSQL Database)
        end
    end

    %% --- Components & Dependencies ---
    C -- HTTP Request --> HPN[Host Port: 8000]
    HPN -- "-p 8000:8000 Mapping" --> DAPP
    DAPP -- "uvicorn main:app" --> DAPP_FAS
    DAPP_FAS -- Reads Env: DB_CONN --> N
    DDB -- Runs --> DDB_PG
    DDB_PG -- Persists Data --> VOL[Volume: postgres-db-volume]
    DAPP --- N
    DDB --- N
    DAPP_FAS -- "SQL Queries (Host: postgres)" --> DDB
    DDB -- Returns Data --> DAPP_FAS
    DAPP -- HTTP Response --> HPN
    HPN --> C
    S -- Manages & Runs --> DAPP
    S -- Manages & Runs --> DDB
    S -- Creates --> N
```
