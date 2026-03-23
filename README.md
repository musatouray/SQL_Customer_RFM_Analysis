# SQL Customer RFM Analysis with dbt + Microsoft Fabric

A [dbt](https://www.getdbt.com/) project that runs a full **RFM (Recency, Frequency, Monetary)** customer segmentation analysis on top of **Microsoft Fabric Data Warehouse**.

---

## Project structure

```
rfm_analysis/
├── dbt_project.yml          # dbt project configuration
├── profiles.yml             # Fabric connection profile template
├── packages.yml             # dbt package dependencies
├── requirements.txt         # Python / pip dependencies
└── models/
    ├── staging/
    │   ├── stg_orders.sql       # Cleans raw orders
    │   ├── stg_customers.sql    # Cleans raw customers
    │   └── schema.yml           # Source + staging model tests
    └── marts/
        ├── rfm_scores.sql       # R/F/M values + 1-5 scores per customer
        ├── customer_segments.sql# Segment labels (Champion, At Risk, …)
        └── schema.yml           # Mart model tests
```

---

## Prerequisites

| Requirement | Version |
|---|---|
| Python | ≥ 3.8 |
| Microsoft ODBC Driver for SQL Server | 17 or **18** (recommended) |
| Azure CLI (for local `cli` auth) | latest |
| Microsoft Fabric Data Warehouse | provisioned workspace |

---

## Quick-start

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure the connection profile

Copy `profiles.yml` to `~/.dbt/profiles.yml` (dbt's default location) and fill in your Fabric endpoint details:

```yaml
rfm_analysis:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server'
      host: "<your-workspace>.datawarehouse.fabric.microsoft.com"
      database: "<your-fabric-database>"
      schema: dbo
      threads: 4
      authentication: cli   # use 'serviceprincipal' for CI/CD (see profiles.yml)
      encrypt: true
      trust_cert: false
```

> **Finding your SQL analytics endpoint:**  
> In the Fabric portal open your Warehouse → *Settings* → copy the **SQL connection string** (it looks like `<guid>-<xyz>.datawarehouse.fabric.microsoft.com`).

#### Authentication options

| Method | When to use | Extra keys required |
|---|---|---|
| `cli` | Local development – uses your `az login` session | – |
| `serviceprincipal` | CI/CD pipelines | `tenant_id`, `client_id`, `client_secret` |
| `password` | Direct SQL credentials | `user`, `password` |

For service principal authentication, set these environment variables and reference them in `profiles.yml`:

```bash
export AZURE_TENANT_ID="..."
export AZURE_CLIENT_ID="..."
export AZURE_CLIENT_SECRET="..."
```

### 3. Install dbt packages

```bash
dbt deps
```

### 4. Verify the connection

```bash
dbt debug
```

### 5. Source tables

The project expects two raw tables in the `dbo` schema of your Fabric warehouse:

| Table | Required columns |
|---|---|
| `orders` | `order_id`, `customer_id`, `order_date`, `order_amount` |
| `customers` | `customer_id`, `customer_name`, `email`, `signup_date` |

Edit `models/staging/schema.yml` to change the source schema or table names.

### 6. Run the models

```bash
# Run everything
dbt run

# Run + test
dbt build

# Run only the RFM marts
dbt run --select marts
```

### 7. Run tests

```bash
dbt test
```

---

## RFM Segmentation logic

Each customer receives a **1–5 score** for each dimension (5 = best):

| Dimension | Meaning | Score direction |
|---|---|---|
| Recency | Days since last purchase | 5 = most recent |
| Frequency | Number of distinct orders | 5 = most orders |
| Monetary | Total amount spent | 5 = highest spend |

Scores are combined into the following segments in `customer_segments`:

| Segment | Description |
|---|---|
| Champion | Bought recently, often, and spend the most |
| Loyal Customer | Buy regularly with high spend |
| Potential Loyalist | Recent buyers with growing frequency |
| New Customer | First-time recent buyers |
| Promising | Recent, average spend |
| Need Attention | Above average but not recently active |
| About To Sleep | Declining recency and frequency |
| At Risk | Big spenders who haven't returned recently |
| Cannot Lose Them | High-value customers at churn risk |
| Hibernating | Long-inactive low-value customers |
| Lost | Lowest scores across all dimensions |

---

## CI/CD with GitHub Actions (optional)

Create `.github/workflows/dbt_run.yml` and add the following secrets to your repository:
`AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `FABRIC_HOST`, `FABRIC_DATABASE`.

```yaml
name: dbt CI

on:
  push:
    branches: [main]

jobs:
  dbt-run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Install ODBC Driver 18
        run: |
          curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
          curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list \
            | sudo tee /etc/apt/sources.list.d/mssql-release.list
          sudo apt-get update
          sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18

      - name: dbt deps
        run: dbt deps

      - name: dbt build
        env:
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        run: |
          dbt build \
            --profiles-dir . \
            --vars '{
              "host": "${{ secrets.FABRIC_HOST }}",
              "database": "${{ secrets.FABRIC_DATABASE }}"
            }'
```

---

## References

- [Set up dbt for Fabric Data Warehouse – Microsoft Learn](https://learn.microsoft.com/en-us/fabric/data-warehouse/tutorial-setup-dbt)
- [dbt-fabric adapter documentation](https://docs.getdbt.com/docs/core/connect-data-platform/fabric-setup)
- [dbt-fabric configuration reference](https://dbt-fabric.debruyn.dev/configuration/)
