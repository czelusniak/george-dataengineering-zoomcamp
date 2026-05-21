# Module 3 — Data Warehouse and BigQuery

## OLTP vs OLAP

### OLTP — Online Transaction Processing

- Back end services
- Fast but small updates
- Normalized, optimized for write speed
- Typical users: customer-facing personnel, online shoppers

### OLAP — Online Analytical Processing

- Analytics
- Larger datasets, periodically refreshed
- Denormalized, optimized for read speed
- Typical users: data analysts and similar roles

![OLTP vs OLAP](https://prod-files-secure.s3.us-west-2.amazonaws.com/f088a10f-676b-46ea-ac34-cc261da4f585/964b2cbc-6839-4127-b972-936f7d9fab03/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB46622AA45GA%2F20260521%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260521T145643Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjED0aCXVzLXdlc3QtMiJHMEUCIQDWBlA0acb%2FA%2BRovKGmns8vTWbruX3FAq%2B%2FUbSTfUNkzQIgYpUH3jQ7nO%2Fm7MsOw5BVmLNh02FkaxvrIzqgX4B7D7Eq%2FwMIBhAAGgw2Mzc0MjMxODM4MDUiDCmvHlQ9H%2FQle9cwvCrcA7%2BYmut8YXppEhdsOaKI8bAPclOTkYctdE2fdCDjjjsU46m9vZr8xb83fTiJ%2BlY%2FLPV3S7FsQ1zlo6KPx37za%2BRdrD4fWSTx89TpwRVTvrioiwAFgYHcRkOP%2BLEvqWiIehGvtYiWKQyVhoKPf78VJiaZ3CAh7Uswpa9Mcv0FOYlB8YLXrUgNs8B%2FImLdzwppwOxYIPeX46G4Vo5nPM%2F%2FkWte1p7M94PESVxn4jAZlSHmJVVgCF1g7jALsLQ0L0kvuOUWvyzNrlyxMRxFdl%2B1Q%2FqTNJ9RNpvRCGSjcrxEW2H5q0IL6%2BwXEh0ZFd5nu82whKwxUCjiDhh8qDPx5BJchHbMVwoeBMER87tfiG2tlxxi%2BkdJqZ9pY1qAFdYVsQPSV4IhXuumxLabmnCubXMD3OGPSOkrF8nxmMQxMc8FLj525en0eOpzV4aeoCLM13cVn598k832pZdTRUr%2BvdxJ%2FY2I%2FgJXFOTFI9i9POFFN6eaRHr%2FMwjf508n4DAdqNUkx1ngd5xcABxcdHwAU9XynsR3h5Q7cbdjrkZ8cqJlqDNhEfSmt3SssMgQ2WIytWz2NssNc2WAGmRzuHpyz4MgdQJBz9NLNfgD7PCOR9zq4bx4R8k4z8qggNxNGcBlMIL7u9AGOqUBvZUNT%2FLqLceUZhErJQ9sfxpTrjNE%2FGKyrQZN69VJyJ92kXS6KleSKKFpL3eLOk5D%2FhNaOw8i%2BmEs%2BGRRR5c6r%2Fh3M6kayY%2Fx7yEG%2Beu1GVh5t6AuFugPH9DfVnv%2FxmbtdIf87IdtLqJawqpyzQRqGE33%2FstYhjyl2yDmtYCII2CVWpK5eSr2371K4M64vgk2bTMVGHUWJ8JCwt1EV4AQX3r1ZLDD&X-Amz-Signature=c5cf365346b83e2134daaed1cef47429294e45c8ae9df951d18b6d5ebe29687e&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject)

## Data Warehouse

**Definição de Data Warehouse:** é apresentado como uma solução OLAP voltada para relatórios e análise de dados. Ele é estruturado internamente por **dados brutos (raw data), metadados e sumários**.

## BigQuery

- Serverless data warehouse
- Principais vantagens:
  - **Serverless**: não há necessidade de gerenciar servidores ou instalar software de banco
  - **Alta escalabilidade e disponibilidade**: escala de gigabytes para **petabytes**
  - **Separação de computação e armazenamento**: mais flexibilidade e boa economia de custos
  - **Recursos integrados**: suporte nativo para **BigQuery ML**, análise geoespacial e BI

### External Table

- Data stays outside BigQuery, usually in GCS
- Lower performance
- Commonly used for raw or staging data
- BigQuery cannot accurately estimate full size or cost

### Native Table

- Data stored inside BigQuery
- Higher performance
- Supports partitioning and clustering
- Full metadata visibility

## Partitioning vs Clustering

### Partitioning

- Splits table into sections, usually by date
- Example:

```sql
PARTITION BY creation_date
```

- BigQuery scans only the needed partitions

### Clustering

- Organizes data inside partitions by column values
- Example:

```sql
CLUSTER BY user_id
```

- BigQuery scans fewer data blocks inside partitions

### Difference

- Partitioning = divide table
- Clustering = organize data inside the table divisions
- `ORDER BY` sorts query results, not physical storage organization
- For table size `< 1 GB`, there is usually no benefit to either approach because metadata reads and maintenance may add cost

### When to use

#### Partitioning

- Queries usually filter by one main column, commonly dates
- Easier cost estimation before query execution
- Common for:
  - logs
  - events
  - time-series analytics

#### Clustering

- Queries usually filter by multiple columns
- Good for high-cardinality columns, for example:
  - `user_id`
  - `transaction_id`
- Better for very large tables

### Important rules

- Too many partitions: prefer clustering
- BigQuery partition limit is around `4000`
- If partitioning would create partitions with `< 1 GB`, clustering may be better
- Frequent writes or updates across many partitions may perform better with clustering

### Mental rule

- Main filter by date?
  - `partitioning`
- Many additional filters?
  - `clustering` too

### Other comparisons

#### Partitioning

- Divides the table into large sections
- Usually based on one main column such as `creation_date`
- Helps BigQuery scan only the necessary partition
- Better when queries usually filter by one column
- Easier cost estimation before running queries
- Good for partition-level management:
  - deleting partitions
  - expiring partitions
- Analogy: choosing the correct library corridor first

#### Clustering

- Organizes data inside partitions
- Groups similar values physically close together
- Better when queries filter by multiple columns

```sql
WHERE creation_date = '2026-05-01'
  AND user_id = 123
  AND country = 'BR'
```

- Works especially well with high-cardinality columns:
  - `user_id`
  - `transaction_id`
  - `email`
- Helps BigQuery scan fewer blocks inside partitions
- Cost and performance improvement is less predictable
- Analogy: organizing books inside the corridor

BigQuery automatically keeps clustered tables organized after new data is inserted.

![Partitioning vs Clustering](https://prod-files-secure.s3.us-west-2.amazonaws.com/f088a10f-676b-46ea-ac34-cc261da4f585/afa48098-3fbf-42dd-8480-9a4e81f77943/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB46622AA45GA%2F20260521%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260521T145643Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjED0aCXVzLXdlc3QtMiJHMEUCIQDWBlA0acb%2FA%2BRovKGmns8vTWbruX3FAq%2B%2FUbSTfUNkzQIgYpUH3jQ7nO%2Fm7MsOw5BVmLNh02FkaxvrIzqgX4B7D7Eq%2FwMIBhAAGgw2Mzc0MjMxODM4MDUiDCmvHlQ9H%2FQle9cwvCrcA7%2BYmut8YXppEhdsOaKI8bAPclOTkYctdE2fdCDjjjsU46m9vZr8xb83fTiJ%2BlY%2FLPV3S7FsQ1zlo6KPx37za%2BRdrD4fWSTx89TpwRVTvrioiwAFgYHcRkOP%2BLEvqWiIehGvtYiWKQyVhoKPf78VJiaZ3CAh7Uswpa9Mcv0FOYlB8YLXrUgNs8B%2FImLdzwppwOxYIPeX46G4Vo5nPM%2F%2FkWte1p7M94PESVxn4jAZlSHmJVVgCF1g7jALsLQ0L0kvuOUWvyzNrlyxMRxFdl%2B1Q%2FqTNJ9RNpvRCGSjcrxEW2H5q0IL6%2BwXEh0ZFd5nu82whKwxUCjiDhh8qDPx5BJchHbMVwoeBMER87tfiG2tlxxi%2BkdJqZ9pY1qAFdYVsQPSV4IhXuumxLabmnCubXMD3OGPSOkrF8nxmMQxMc8FLj525en0eOpzV4aeoCLM13cVn598k832pZdTRUr%2BvdxJ%2FY2I%2FgJXFOTFI9i9POFFN6eaRHr%2FMwjf508n4DAdqNUkx1ngd5xcABxcdHwAU9XynsR3h5Q7cbdjrkZ8cqJlqDNhEfSmt3SssMgQ2WIytWz2NssNc2WAGmRzuHpyz4MgdQJBz9NLNfgD7PCOR9zq4bx4R8k4z8qggNxNGcBlMIL7u9AGOqUBvZUNT%2FLqLceUZhErJQ9sfxpTrjNE%2FGKyrQZN69VJyJ92kXS6KleSKKFpL3eLOk5D%2FhNaOw8i%2BmEs%2BGRRR5c6r%2Fh3M6kayY%2Fx7yEG%2Beu1GVh5t6AuFugPH9DfVnv%2FxmbtdIf87IdtLqJawqpyzQRqGE33%2FstYhjyl2yDmtYCII2CVWpK5eSr2371K4M64vgk2bTMVGHUWJ8JCwt1EV4AQX3r1ZLDD&X-Amz-Signature=385718ddd65bf9eb954f3c41aa91e5346224126555c4a742ce92bc05ec0b42e5&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject)

## BigQuery Best Practices

### Reduce cost

- Avoid `SELECT *` because it reads all columns
- Review estimated price before running queries
- Streaming inserts can increase costs, prefer batch loads when possible
- Materialize intermediate query results in staging tables instead of repeatedly recalculating large CTEs
- Prefer modular and DRY queries over repeating heavy transformations

### Improve performance

- Filter on partitioned or clustered columns
- Denormalize data
  - Wide tables are optimized for querying
  - Reduces expensive joins
  - Common in data warehouses
  - Normalized = smaller tables, many joins
  - Denormalized = wide single table, faster reads, fewer joins, but more duplicated data
- Use nested and repeated columns
- Query external storage sparingly
- Reduce data before using `JOIN`
  - filter or aggregate first
  - then join smaller datasets
- Do not treat `WITH` clauses as prepared statements
  - CTEs may be recalculated
  - prefer materializing into tables
- Avoid over-sharding tables
  - avoid creating many separate tables like:
    - `sales_2023`
    - `sales_2024`
    - `sales_2025`
  - prefer partitioned tables instead
- Avoid JavaScript UDFs when possible
- Put `ORDER BY` last
  - sorting is expensive
  - sort only final results when necessary
- Optimize join pattern, usually with the largest table first

## Nested Columns

Colunas que contêm estruturas ou objetos dentro delas (`STRUCT`).

- Objeto: estrutura com propriedades nomeadas

Flat table:

```text
| order_id | customer_name | customer_country |
|----------|---------------|------------------|
| 1        | George        | Brazil           |
```

Nested table:

```text
| order_id | customer                      |
|----------|-------------------------------|
| 1        | {name:'George', country:'BR'} |
```

Acessando nested fields:

```sql
SELECT customer.name
FROM orders
```

## Repeated Columns

Repeated = arrays ou listas dentro da coluna.

- Array: lista de elementos

Exemplo:

```text
| order_id | items                 |
|----------|-----------------------|
| 1        | ['Mouse', 'Keyboard'] |
```

`items` é um array.

## Internals of BigQuery

- BigQuery separates storage and compute
  - Storage is cheap and independent from query execution
  - Data is stored in Colossus and computation happens separately
  - Main benefit: scalability plus cost efficiency
- Os pilares dessa infraestrutura são o **Colossus** (armazenamento), a rede **Jupiter** (conectividade) e o **Dremel** (motor de execução de consultas)
- BigQuery uses columnar storage
  - Data is stored by columns instead of rows
  - Queries read only the necessary columns
  - Better for:
    - aggregations
    - analytics
    - compression
  - Example:
    - `SELECT user_id` reads only the `user_id` column
- Dremel is the distributed query engine
  - BigQuery transforms queries into execution trees
  - Work is split across thousands of workers in parallel
  - Main reason for BigQuery's high speed on massive datasets
- Query execution hierarchy
  - Root Server:
    - receives and coordinates the query
  - Mixers:
    - aggregate and distribute intermediate results
  - Leaf Nodes:
    - read data directly from Colossus
- Jupiter network enables extremely fast communication
  - Connects compute and storage infrastructure
  - Designed for ultra-high throughput and low latency
  - Helps BigQuery process petabyte-scale data efficiently
- BigQuery performance comes from parallelism
  - Large queries are broken into many smaller tasks
  - Thousands of workers process data simultaneously
- Why BigQuery is fast:
  - columnar storage
  - massive distributed execution
  - high-speed internal networking
  - parallel processing architecture
- Important mindset:
  - BigQuery is optimized for OLAP and analytics workloads
  - It is not designed like traditional transactional databases (OLTP)

![BigQuery internals 1](https://prod-files-secure.s3.us-west-2.amazonaws.com/f088a10f-676b-46ea-ac34-cc261da4f585/2e798e4a-5525-4bae-a318-56cc22c02128/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB46622AA45GA%2F20260521%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260521T145643Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjED0aCXVzLXdlc3QtMiJHMEUCIQDWBlA0acb%2FA%2BRovKGmns8vTWbruX3FAq%2B%2FUbSTfUNkzQIgYpUH3jQ7nO%2Fm7MsOw5BVmLNh02FkaxvrIzqgX4B7D7Eq%2FwMIBhAAGgw2Mzc0MjMxODM4MDUiDCmvHlQ9H%2FQle9cwvCrcA7%2BYmut8YXppEhdsOaKI8bAPclOTkYctdE2fdCDjjjsU46m9vZr8xb83fTiJ%2BlY%2FLPV3S7FsQ1zlo6KPx37za%2BRdrD4fWSTx89TpwRVTvrioiwAFgYHcRkOP%2BLEvqWiIehGvtYiWKQyVhoKPf78VJiaZ3CAh7Uswpa9Mcv0FOYlB8YLXrUgNs8B%2FImLdzwppwOxYIPeX46G4Vo5nPM%2F%2FkWte1p7M94PESVxn4jAZlSHmJVVgCF1g7jALsLQ0L0kvuOUWvyzNrlyxMRxFdl%2B1Q%2FqTNJ9RNpvRCGSjcrxEW2H5q0IL6%2BwXEh0ZFd5nu82whKwxUCjiDhh8qDPx5BJchHbMVwoeBMER87tfiG2tlxxi%2BkdJqZ9pY1qAFdYVsQPSV4IhXuumxLabmnCubXMD3OGPSOkrF8nxmMQxMc8FLj525en0eOpzV4aeoCLM13cVn598k832pZdTRUr%2BvdxJ%2FY2I%2FgJXFOTFI9i9POFFN6eaRHr%2FMwjf508n4DAdqNUkx1ngd5xcABxcdHwAU9XynsR3h5Q7cbdjrkZ8cqJlqDNhEfSmt3SssMgQ2WIytWz2NssNc2WAGmRzuHpyz4MgdQJBz9NLNfgD7PCOR9zq4bx4R8k4z8qggNxNGcBlMIL7u9AGOqUBvZUNT%2FLqLceUZhErJQ9sfxpTrjNE%2FGKyrQZN69VJyJ92kXS6KleSKKFpL3eLOk5D%2FhNaOw8i%2BmEs%2BGRRR5c6r%2Fh3M6kayY%2Fx7yEG%2Beu1GVh5t6AuFugPH9DfVnv%2FxmbtdIf87IdtLqJawqpyzQRqGE33%2FstYhjyl2yDmtYCII2CVWpK5eSr2371K4M64vgk2bTMVGHUWJ8JCwt1EV4AQX3r1ZLDD&X-Amz-Signature=205096348d9c215adca53f8e2a7d2cb4077b871f89a850fe90257f77151e38e0&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject)

![BigQuery internals 2](https://prod-files-secure.s3.us-west-2.amazonaws.com/f088a10f-676b-46ea-ac34-cc261da4f585/8a49480a-72fd-4b5f-921b-f5a2f6394127/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB46622AA45GA%2F20260521%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260521T145643Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjED0aCXVzLXdlc3QtMiJHMEUCIQDWBlA0acb%2FA%2BRovKGmns8vTWbruX3FAq%2B%2FUbSTfUNkzQIgYpUH3jQ7nO%2Fm7MsOw5BVmLNh02FkaxvrIzqgX4B7D7Eq%2FwMIBhAAGgw2Mzc0MjMxODM4MDUiDCmvHlQ9H%2FQle9cwvCrcA7%2BYmut8YXppEhdsOaKI8bAPclOTkYctdE2fdCDjjjsU46m9vZr8xb83fTiJ%2BlY%2FLPV3S7FsQ1zlo6KPx37za%2BRdrD4fWSTx89TpwRVTvrioiwAFgYHcRkOP%2BLEvqWiIehGvtYiWKQyVhoKPf78VJiaZ3CAh7Uswpa9Mcv0FOYlB8YLXrUgNs8B%2FImLdzwppwOxYIPeX46G4Vo5nPM%2F%2FkWte1p7M94PESVxn4jAZlSHmJVVgCF1g7jALsLQ0L0kvuOUWvyzNrlyxMRxFdl%2B1Q%2FqTNJ9RNpvRCGSjcrxEW2H5q0IL6%2BwXEh0ZFd5nu82whKwxUCjiDhh8qDPx5BJchHbMVwoeBMER87tfiG2tlxxi%2BkdJqZ9pY1qAFdYVsQPSV4IhXuumxLabmnCubXMD3OGPSOkrF8nxmMQxMc8FLj525en0eOpzV4aeoCLM13cVn598k832pZdTRUr%2BvdxJ%2FY2I%2FgJXFOTFI9i9POFFN6eaRHr%2FMwjf508n4DAdqNUkx1ngd5xcABxcdHwAU9XynsR3h5Q7cbdjrkZ8cqJlqDNhEfSmt3SssMgQ2WIytWz2NssNc2WAGmRzuHpyz4MgdQJBz9NLNfgD7PCOR9zq4bx4R8k4z8qggNxNGcBlMIL7u9AGOqUBvZUNT%2FLqLceUZhErJQ9sfxpTrjNE%2FGKyrQZN69VJyJ92kXS6KleSKKFpL3eLOk5D%2FhNaOw8i%2BmEs%2BGRRR5c6r%2Fh3M6kayY%2Fx7yEG%2Beu1GVh5t6AuFugPH9DfVnv%2FxmbtdIf87IdtLqJawqpyzQRqGE33%2FstYhjyl2yDmtYCII2CVWpK5eSr2371K4M64vgk2bTMVGHUWJ8JCwt1EV4AQX3r1ZLDD&X-Amz-Signature=93f1c224ff4be11f393ceeeb49041020943a7e9e18e6f9cac7ba78d9f0b5a359&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject)
