# Data Engineering ZoomCamp 2026

Personal repository for my work in the [Data Engineering ZoomCamp](https://github.com/DataTalksClub/data-engineering-zoomcamp), including hands-on exercises, study notes, and project files organized by module.

## Repository Structure

| Module | Topic | Main Tools |
| --- | --- | --- |
| `01-docker-terraform-gcp/` | Containerization and Infrastructure | Docker, PostgreSQL, pgAdmin, Terraform, GCP |
| `02-workflow-orchestration/` | Workflow Orchestration | Kestra, PostgreSQL, GCP, BigQuery |
| `03-data-warehouse/` | Data Warehouse | BigQuery |
| `04-analytics-engineering/` | Analytics Engineering | DuckDB, dbt, SQL |

Each module folder contains its own notes, exercises, and supporting files.

## Current Focus

The most active area right now is [`04-analytics-engineering/`](./04-analytics-engineering), where I am learning dbt step by step by comparing my local project with the course reference and implementing changes gradually.

## How To Use This Repo

This repository is organized by module rather than as a single runnable project.

- Read the module `README.md` files for notes and context.
- Run commands from the specific module directory you are working on.
- Check each module for its own environment variables, dependencies, and `docker-compose.yml` if applicable.

## Quick Start

For modules that use Docker Compose:

1. Go to the relevant module directory.
2. Copy `.env.example` to `.env` when the module provides one.
3. Fill in the required credentials and configuration.
4. Start the services with:

```bash
docker compose up -d
```

For the dbt module:

1. Open [`04-analytics-engineering/taxi_rides_ny/`](./04-analytics-engineering/taxi_rides_ny).
2. Configure your local dbt profile.
3. Run `dbt debug`, `dbt run`, and `dbt test` from that directory.
