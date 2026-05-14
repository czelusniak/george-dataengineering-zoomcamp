# Learning Notes — DE ZoomCamp 2026 — Module 1

Personal file to document what each tool does and why it is used in the context of data engineering.

**Module 1: Containerization & Infrastructure as Code** — build a solid foundation for running data engineering workloads in reproducible, isolated environments. Rather than installing databases and tools directly on your machine, everything runs inside Docker containers — ensuring the setup works the same way on any computer.

---

## Docker & PostgreSQL

Covers the full journey of building a local data pipeline from scratch using Docker and PostgreSQL:

1. **Introduction to Docker** — What containers are, why they're stateless, and basic commands
2. **Virtual Environments** — Setting up Python projects with `uv` for isolated dependencies
3. **Dockerizing a Pipeline** — Writing a `Dockerfile` to package a Python script into an image
4. **PostgreSQL with Docker** — Running a database in a container with volumes for persistence
5. **Data Ingestion** — Loading the NY Taxi dataset (CSV) into PostgreSQL using pandas + SQLAlchemy
6. **Ingestion Script** — Converting a Jupyter notebook into a reusable CLI script with `click`
7. **pgAdmin** — Adding a web-based GUI for the database; connecting two containers via a Docker network
8. **Dockerizing the Ingestion** — Running the ingestion script itself inside a container
9. **Docker Compose** — Replacing multiple `docker run` commands with a single `docker-compose.yaml`
10. **SQL Refresher** — Joins, aggregations, and analytical queries on the taxi dataset
11. **Cleanup** — Removing containers, images, volumes, and networks

The concrete outcome is a fully containerized local data stack: PostgreSQL + pgAdmin + an ingestion pipeline, all wired together with Docker Compose.

---

### 01 — Introduction to Docker
- A **container** is an isolated environment with everything an app needs to run — like a shipping container, it works the same way on any machine
- Docker solves the "it works on my machine" problem: the same container runs identically on a laptop, a teammate's machine, or a cloud server
- Containers are **stateless** by default — any files created inside are gone when the container stops. **Volumes** solve this: they link a folder inside the container to a folder on your machine so data survives
- Docker Hub is a public library of ready-to-use images (PostgreSQL, Python, Ubuntu…) — no need to build from scratch

---

### 02 — Virtual Environments and Data Pipelines
- A **data pipeline** is a service that receives data as input, processes it, and outputs it somewhere else (e.g. CSV → PostgreSQL)
- Projects need their own isolated set of libraries so they don't conflict with each other — this is what a **virtual environment** is
- `uv` is the tool used in this course to manage those isolated environments — it handles installing libraries and running scripts inside the right environment automatically

---

### 03 — Dockerizing a Pipeline
- A `Dockerfile` is a recipe to build a Docker image with your app and its dependencies
- `docker build -t name:tag .` builds the image from the Dockerfile in the current folder
- `docker run image arg` runs the container passing arguments to the ENTRYPOINT
- Copy dependency files (`pyproject.toml`, `uv.lock`) before the app code to maximize Docker layer caching — if only the code changes, dependencies are not reinstalled
- Use `--entrypoint=bash` to override the default entrypoint and explore the container interactively
- Files created inside a container are lost when the container is removed — use `-v` (volumes) to persist them on your machine
- To interactively explore files inside a container: `docker run -it --rm --entrypoint=bash test:pandas`

---

### 04 — PostgreSQL with Docker
- `docker run postgres:18` does not require `docker build` — official images (postgres, python, ubuntu) are pre-built and hosted on Docker Hub. Docker downloads them automatically if not found locally
- `docker build` is only needed when you create your own image from a `Dockerfile`

**Architecture overview:**

```mermaid
graph TD
    subgraph WSL["Your Computer (WSL)"]
        subgraph container["Container — postgres:18"]
            pg["PostgreSQL port 5432"]
            vol[("Volume ny_taxi_postgres_data")]
            pg --> vol
        end

        subgraph uv["uv environment (pipeline/)"]
            pgcli["pgcli"]
            pandas["pandas / pyarrow"]
        end
    end

    pgcli -->|"localhost:5432 → container:5432"| pg
```

**Named Volume vs Bind Mount:**

| | Named Volume | Bind Mount |
|---|---|---|
| Syntax | `name:/path` | `$(pwd)/folder:/path` |
| Managed by | Docker (internal) | You (local folder) |
| Easy to use | Yes | No |
| Files accessible | No (stored in `/var/lib/docker/volumes/`) | Yes |
| When to use | Production | Development |

---

### 05 — Data Ingestion
- **SQLAlchemy** is used to insert data into PostgreSQL because pandas' `to_sql()` method requires it as a connection layer
- `df.head(n=0).to_sql(...)` creates the table schema without inserting data
- Data is read and inserted in **chunks** (`chunksize=100000`) to avoid loading the full file into memory at once
- An iterator is a "tape" — once you loop through it to the end, it's exhausted. You must recreate it to iterate again
- `parse_dates` and `dtype` in `pd.read_csv()` convert column types at read time — without them, everything is read as plain text
- The Complete Ingestion Loop creates the table schema from the first chunk itself (no need for a separate `df`), then inserts all chunks with `if_exists='append'`
- `get_schema()` is a preview of the `CREATE TABLE` SQL that pandas would generate — useful to verify column types before creating the table

---

### 06 — Ingestion Script
- `nbconvert --to=script notebook.ipynb` converts a Jupyter notebook to a `.py` script — useful to move from exploration to production
- When running `uv run python ingest_data.py`, **no new container is created**. The script runs on your machine (WSL) and connects to the already-running PostgreSQL container via `localhost:5432`
- The PostgreSQL container must be running in a separate terminal before executing the script
- Organizing code inside a `run()` function + `if __name__ == '__main__'` makes the script reusable as a module and cleaner than loose code
- Notebook code exported via `nbconvert` needs cleanup: remove exploratory lines (`df.head()`, `df.dtypes`), organize into functions, and replace hardcoded values with variables

**How `uv run python ingest_data.py` works behind the scenes:**
- PostgreSQL was already running in a separate container (Terminal 1)
- `ingest_data.py` runs on your computer (WSL), outside any container
- The two communicate via port 5432
- No new container is created when running the script

---

### 07 — pgAdmin & Networking

**localhost, ports and Docker networking — key concepts:**
- `localhost` = "this computer" — always refers to wherever the program is running
- A **port** is like an apartment number in a building (the IP/localhost is the building address) — each server program listens on a specific port (PostgreSQL = 5432, Jupyter = 8888)
- Only the **server** port matters — the client (pgcli) gets a random temporary port assigned automatically by the OS
- `-p 5432:5432` creates a tunnel between your computer's port 5432 and the container's port 5432 — without it, the container is invisible from outside
- Two containers cannot communicate via `localhost` — each has its own localhost (their own "building")
- **Docker Network** puts containers on the same virtual network where they can find each other by container name instead of localhost

**Which host to use:**

| Situation | Host |
|---|---|
| pgcli on WSL → PostgreSQL in container | `localhost` (thanks to `-p`) |
| container → PostgreSQL in another container | container name (via network) |
| container → PostgreSQL on WSL | IP of the computer |

**localhost with Docker — two cases:**
- **Case 1** — pgcli and PostgreSQL on the same computer: `pgcli → localhost → PostgreSQL on your machine`
- **Case 2** — pgcli on your computer, PostgreSQL in a container: `pgcli → localhost → Docker redirects via -p 5432:5432 → PostgreSQL in container`. Still `localhost` because Docker makes the container appear as if it were running on your own computer. Without `-p`, the PostgreSQL would be invisible.

**Two containers — service vs task:**
- **Container 1 (PostgreSQL):** pre-built image from Docker Hub, no build needed. Stays running listening on port 5432. Data saved in volume `ny_taxi_postgres_data`
- **Container 2 (taxi_ingest):** built from your Dockerfile. Runs `ingest_data.py`, downloads the CSV, inserts into PostgreSQL, then dies
- Container 1 is a **service** — keeps running waiting for connections
- Container 2 is a **task** — executes one thing and terminates
- Both communicate via `pg-network` using the name `pgdatabase` as the address

**Commands used:**
```bash
# 1. Create the network
docker network create pg-network

# 2. Start PostgreSQL on the network
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  --network=pg-network \
  --name pgdatabase \
  postgres:18

# 3. Run the ingestion container
docker run -it \
  --network=pg-network \
  taxi_ingest:v001 \
  --pg-user=root \
  --pg-pass=root \
  --pg-host=pgdatabase \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips_2021_1

# 4. Start pgAdmin on the same network
docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -v pgadmin_data:/var/lib/pgadmin \
  -p 8085:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4
```

**Why two containers cannot talk via localhost:**

```mermaid
graph TD
    subgraph WSL["Your Computer (WSL)"]
        subgraph c1["Container: taxi_ingest"]
            ingest["ingest_data.py"]
            loc1["localhost:5432"]
            nothing["port 5432: EMPTY"]
            ingest -->|tries to connect| loc1
            loc1 --> nothing
            nothing -->|Connection refused!| ingest
        end

        subgraph c2["Container: postgres"]
            pg["PostgreSQL port 5432"]
        end
    end

    style nothing fill:#f44,color:#fff
```

**How it works with Docker Network:**

```mermaid
graph TD
    subgraph WSL["Your Computer (WSL)"]
        subgraph network["Docker Network: pg_network"]
            subgraph c1["Container: taxi_ingest"]
                ingest["ingest_data.py"]
            end

            subgraph c2["Container: pg_container"]
                pg["PostgreSQL port 5432"]
            end

            ingest -->|pg_container:5432| pg
            pg -->|data| ingest
        end
    end

    style pg fill:#4CAF50,color:#fff
    style ingest fill:#2196F3,color:#fff
```

---

### 09 — Docker Compose
- Docker Compose replaces multiple `docker run` commands with a single `docker-compose.yaml` file
- Only **services** (containers that stay running) go in the compose file — `pgdatabase` and `pgadmin`
- **Tasks** (containers that run once and die) like `taxi_ingest` stay as separate `docker run` commands
- Docker Compose creates a network automatically — no need to run `docker network create` manually
- Containers find each other by their service name (e.g. `pgdatabase`) — same as with a manually created network
- To run the ingestion after compose is up, find the auto-created network with `docker network ls` and pass it to `docker run --network=<network>`
- Docker Compose prefixes volume and network names with the folder name (e.g. `pipeline_ny_taxi_postgres_data`)

---

### Tools

#### Docker
**What it is:** A tool that packages your application and all its dependencies into a self-contained unit called a **container**. Think of it like a shipping container — everything the app needs to run is inside, and it works the same way on any machine.
**Why use it:** Eliminates the "it works on my machine" problem. A container runs identically on your laptop, a teammate's machine, or a cloud server. In this course, we use Docker to run PostgreSQL and other services without installing them directly on your computer.
**When to use it:** Whenever you want to run a service or application in an isolated, reproducible environment.

**ENTRYPOINT — bash vs python:**
- `ENTRYPOINT ["python", "pipeline.py"]` in the Dockerfile → `docker run image 16` passes `16` as argument to the script
- `--entrypoint=bash` in `docker run` → overrides the Dockerfile entrypoint, opens an interactive shell. Any argument after the image name is treated as a bash argument, not a Python one
- To explore the container and run the script manually: `docker run -it --rm --entrypoint=bash image` then `python pipeline.py 16` inside

---

#### Docker Compose
**What it is:** A tool that lets you define and run multiple Docker containers together using a single YAML file.
**Why use it:** Replaces multiple `docker run` commands with a single `docker compose up`. Also creates a network automatically so containers can talk to each other by service name.
**When to use it:** Whenever you have multiple services that need to run together (e.g. PostgreSQL + pgAdmin).
**Key commands:**
```bash
docker compose up       # start all services in foreground
docker compose up -d    # start in background (detached mode)
docker compose down     # stop and remove containers
docker compose down -v  # also removes volumes
```

---

#### PostgreSQL
**What it is:** A relational database — stores data in tables with rows and columns, and lets you query it with SQL.
**Why use it:** Industry standard open-source database. Used in this course to store and query NYC taxi trip data.
**When to use it:** When you need structured data storage with SQL querying capabilities.
**Key commands:**
```bash
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi   # connect
\dt        # list tables
\q         # exit
```

---

#### uv
**What it is:** A modern Python package and project manager written in Rust. Much faster than pip and handles virtual environments automatically.
**Why use it:** Replaces the manual venv + pip workflow with a single tool. Reproducible environments via `uv.lock`.
**When to use it:** Any new Python project where you want isolated dependencies without the manual activation overhead.
**Key commands:**
```bash
uv init --python=3.13    # creates the project and pyproject.toml
uv add pandas pyarrow    # installs packages (creates/updates .venv)
uv run python script.py  # runs a file using the isolated environment
uv remove pandas         # removes a package
```
**Files it creates:**
- `pyproject.toml` — project config and dependencies list
- `uv.lock` — locks exact package versions for reproducibility
- `.python-version` — stores which Python version the project uses

---

#### pgcli
**What it is:** A command-line client for PostgreSQL with auto-completion and syntax highlighting.
**Why use it:** Easier to use than the default `psql` client. Lets you run SQL queries directly from the terminal.
**When to use it:** When you want to quickly inspect or query a PostgreSQL database without opening pgAdmin.

---

#### pgAdmin
**What it is:** A web-based GUI for PostgreSQL. Access it via the browser.
**Why use it:** Easier to explore tables, run queries and visualize data than the command line.
**When to use it:** When you want a visual interface to interact with PostgreSQL.
**Access:** `http://localhost:8085`

---

#### SQLAlchemy
**What it is:** A Python library that acts as a bridge between Python and databases.
**Why use it:** Pandas' `to_sql()` method requires it to connect to PostgreSQL. You don't write raw SQL to insert rows — pandas handles it using SQLAlchemy under the hood.
**Connection string format:** `postgresql+psycopg://user:password@host:port/database`

---

#### click
**What it is:** A Python library for creating command-line interfaces.
**Why use it:** Replaces `sys.argv` with a cleaner, more readable way to define CLI arguments with defaults, types, and help text.
**Key difference:**
```bash
# sys.argv — positional, easy to get the order wrong
python script.py root root localhost 5432

# click — named, order doesn't matter
python script.py --pg-user root --pg-host localhost
```

---

## Terraform & GCP

Introduces Infrastructure as Code (IaC) to provision cloud resources on Google Cloud Platform:
- Terraform basics: `init`, `plan`, `apply`, `destroy`
- GCP concepts: projects, service accounts, Storage (GCS), BigQuery
- Creating and destroying cloud infrastructure declaratively from code

---

### GCP

**What it is:** Google Cloud Platform — Google's cloud services platform. Provides infrastructure (servers, storage, networking) and managed services (databases, pipelines, ML) accessible over the internet, without needing to maintain physical hardware.

**What it's for:** Running data engineering workloads in the cloud — storing raw data, processing large volumes, creating warehouses, and orchestrating pipelines — without managing physical servers.

**Service categories relevant to data engineering:**

| Category | GCP Service | Purpose |
|---|---|---|
| File storage | Google Cloud Storage (GCS) | Stores raw files (CSV, Parquet, JSON) — like a hard drive in the cloud |
| Data Warehouse | BigQuery | Analytical database for SQL queries on large data volumes |
| Orchestration | Cloud Composer | Managed version of Apache Airflow for orchestrating pipelines |
| Processing | Dataproc | Managed Apache Spark cluster for distributed processing |
| Identity & access | IAM / Service Accounts | Controls who (person or service) can do what inside a GCP project |

In this course, the focus is on **GCS** (raw layer storage) and **BigQuery** (warehouse for analysis).

---

### Terraform

**What it is:** An open-source tool by HashiCorp for creating and managing cloud infrastructure (servers, buckets, databases, networks) using code — instead of clicking manually through the AWS, GCP, or Azure console.

**What it's for:** Defines infrastructure resources in `.tf` files (declarative text) and applies those definitions to the cloud with a few commands. Infrastructure becomes versionable code in Git, just like application code. Practical examples for data engineering:
- Create a **Google Cloud Storage bucket** to store raw pipeline files (the NY Taxi CSVs, for example)
- Create a **BigQuery dataset** where the analysis tables will live — without clicking through the GCP console every time the environment is rebuilt

**Why Terraform?**
- **Simplicity in tracking infrastructure** — everything running in the cloud is described in text files. To know what's running, just open the `.tf` — no need to navigate the GCP console
- **Easier collaboration** — the files live in Git, just like code. The team can review, comment, and version infrastructure changes like pull requests
- **Reproducibility** — the same set of files creates identical environments (dev, staging, production). No surprises of "it works on my machine but not on yours"
- **Guaranteed cleanup** — `terraform destroy` removes everything that was created, leaving no forgotten resources running and generating cloud costs

**What Terraform is not:**
- **Does not manage code on infrastructure** — Terraform creates and configures resources (e.g. a VM on GCP), but does not deploy your application onto them. For that, there are other tools like Ansible, Chef, or CI/CD scripts. Examples of what this means in practice:
  - Terraform creates the GCS bucket — but it's your Python script that uploads the CSV files into it
  - Terraform creates the BigQuery dataset — but it's dbt or your ingestion pipeline that runs the queries and loads the data
- **Cannot change immutable resources** — some resources cannot be modified after creation (e.g. changing the disk type of a bucket). In that case, Terraform destroys the old resource and creates a new one — which can cause data loss if not planned for
- **Does not manage resources not defined in your files** — if you create a resource manually through the GCP console and it's not in the `.tf`, Terraform doesn't know it exists and won't touch it. The state only reflects what was declared

**Providers:**
A provider is the plugin that teaches Terraform how to talk to a specific platform — GCP, AWS, Azure, etc. Without the provider, Terraform doesn't know what a bucket, a VM, or a dataset is.

- Each provider is developed and maintained by the platform's own company (Google maintains the GCP provider, Amazon maintains the AWS one)
- It's declared in `main.tf` and downloaded automatically by `terraform init`
- The provider translates the `resource` blocks in your `.tf` into API calls to the platform — you write `google_storage_bucket`, the provider knows how to create that on GCP

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = "us-central1"
}
```

In this example: `terraform init` downloads the Google plugin, and from that point any `resource "google_*"` in the file knows how to communicate with GCP.

**Basic workflow:**
```bash
terraform init     # downloads the provider plugins (e.g. GCP)
terraform plan     # shows what will be created/modified/destroyed — without changing anything
terraform apply    # applies the changes to the cloud (asks for confirmation)
terraform destroy  # removes everything that was created
```

**Main files:**
- `main.tf` — defines the resources (buckets, datasets, etc.)
- `variables.tf` — declares reusable variables (e.g. project name, region)
- `terraform.tfstate` — auto-generated file that tracks the current state of the infrastructure. **Never edit manually.**

---

### Hands-on

#### Setting up a Service Account on GCP
A **Service Account** is an identity for programs — not people. Instead of using your personal Google login, you create a dedicated account for Terraform with only the permissions it needs (e.g. create buckets and datasets). This is more secure and auditable.

Created service account: `terraform-runner-sa` with the following roles:

| Role | What it allows |
|---|---|
| **Storage Admin** | Create, delete, and manage GCS buckets — needed to provision the raw data lake |
| **BigQuery Admin** | Create and manage BigQuery datasets and tables — needed to provision the data warehouse |
| **Compute Admin** | Create and manage VMs and compute resources — needed if the pipeline requires cloud compute (e.g. Dataproc) |

#### Managing Keys
For Terraform to prove it is that Service Account, it needs a key — a JSON file generated in the GCP console. This file works like a password: anyone who has it can act as the Service Account. That's why it **must never be committed to Git**.

#### Creating main.tf
The central file of a Terraform project. This is where you declare which resources you want to create in the cloud (buckets, datasets, etc.) and which provider to use. It's the equivalent of `docker-compose.yaml`, but for cloud infrastructure.

#### Setting up Credentials and Providers
Configures the GCP provider in `main.tf` by pointing to the Service Account key file. From that point, Terraform knows which GCP project to talk to and has permission to create resources in it.

#### terraform init
The first command to run in any Terraform project. Reads `main.tf`, downloads the declared provider plugin (e.g. google), and prepares the working directory. Only needs to run once — or when the provider changes.

#### Creating a BigQuery Dataset
Similar to the bucket — add a `resource "google_bigquery_dataset"` block to `main.tf`. This is the data warehouse where processed data will be stored and queried.

#### variables.tf
Extracts hardcoded values (project ID, region, resource names) into a separate file. Keeps `main.tf` clean and makes the project easier to reuse across different environments without touching the main configuration.

#### Enabling GCP APIs
Some GCP services are disabled by default and must be explicitly enabled before Terraform can use them. For this course, two APIs are required: **IAM API** and **IAM Credentials API**.
---

## Concepts

### Data Pipeline
A service that receives data as input, transforms it, and outputs it somewhere else (e.g. CSV → PostgreSQL).

### Idempotency
A pipeline is idempotent when running it multiple times produces the same result. Important for reliability — if a pipeline fails and is re-run, it shouldn't duplicate or corrupt data.

---



