# Checklist de alinhamento com a referencia dbt do curso

Objetivo: alinhar o projeto `taxi_rides_ny` com a estrutura da referencia em `course-materials/04-analytics-engineering/taxi_rides_ny`, antes de evoluir o `fct_trips.sql`.

## Ordem sugerida

1. Adicionar dependencias do projeto

   Criar `taxi_rides_ny/packages.yml` com as dependencias usadas na referencia:

   - `dbt-labs/dbt_utils`
   - `dbt-labs/codegen`

   Isso permite usar macros como `dbt_utils.generate_surrogate_key()`.

2. Ajustar `dbt_project.yml`

   Configurar as materializacoes por camada:

   - `staging`: `view`
   - `intermediate`: `table`
   - `marts`: `table`

3. Alinhar `int_trips_unioned.sql`

   Atualizar `models/intermediate/int_trips_unioned.sql` para:

   - selecionar colunas explicitamente em vez de `select *`;
   - normalizar o schema entre green e yellow taxi;
   - usar `Green` e `Yellow` em `service_type`;
   - preencher campos que existem em apenas um tipo de taxi, como `trip_type` e `ehail_fee`.

4. Criar `models/intermediate/int_trips.sql`

   Esse modelo deve:

   - ler de `int_trips_unioned`;
   - gerar `trip_id`;
   - enriquecer `payment_type` com uma descricao;
   - tratar `payment_type` nulo como `0`;
   - deduplicar as viagens com `qualify row_number()`.

5. Simplificar `fct_trips.sql`

   Atualizar `models/marts/fct_trips.sql` para:

   - ler de `{{ ref('int_trips') }}`;
   - parar de gerar `trip_id`;
   - parar de deduplicar;
   - manter a tabela fato como camada final de mart;
   - fazer joins com dimensoes, como `dim_zones`.

6. Criar `models/intermediate/schema.yml`

   Documentar e testar os modelos intermediarios:

   - `int_trips_unioned`;
   - `int_trips`;
   - `trip_id` com `unique` e `not_null`;
   - `service_type` com valores aceitos `Green` e `Yellow`;
   - campos essenciais como `vendor_id`, `pickup_datetime` e `total_amount`.

7. Criar ou alinhar `models/marts/schema.yml`

   Documentar e testar os marts principais:

   - `dim_zones`;
   - `dim_vendors`;
   - `fct_trips`.

8. Rodar validacoes

   Depois dos ajustes, executar:

   ```bash
   dbt deps
   dbt seed
   dbt run --select int_trips_unioned int_trips fct_trips
   dbt test --select int_trips fct_trips
   ```

## Divisao de responsabilidade por camada

- `staging`: limpa e padroniza nomes/tipos vindos das fontes raw.
- `intermediate/int_trips_unioned`: une green e yellow taxi em um schema comum.
- `intermediate/int_trips`: gera chave, enriquece pagamento e remove duplicatas.
- `marts/fct_trips`: tabela fato final para analise, com joins de dimensoes.

## Nota sobre memoria no DuckDB

Durante a etapa de deduplicacao em `int_trips.sql`, o comando abaixo pode falhar com `Out of Memory`:

```bash
dbt run --select int_trips
```

O ponto pesado e o `qualify row_number()`:

```sql
qualify row_number() over (
    partition by vendor_id, pickup_datetime, pickup_location_id, service_type
    order by dropoff_datetime
) = 1
```

Esse trecho exige ordenacao e particionamento de muitos registros. Como o DuckDB roda localmente dentro da memoria do WSL, ele pode estourar o limite mesmo quando o SQL esta correto.

O que foi observado:

- com `memory_limit: '4GB'`, o erro ocorreu perto de `3.7 GiB`;
- com `memory_limit: '6GB'`, o erro ocorreu perto de `5.5 GiB`;
- com `memory_limit: '8GB'`, o erro ocorreu perto de `7.4 GiB`;
- `preserve_insertion_order: false` ja estava configurado em `~/.dbt/profiles.yml`;
- `threads: 1` ja estava configurado.

Decisao temporaria para seguir o tutorial:

- manter `models/intermediate/int_trips.sql` como `view`;
- manter `models/marts/fct_trips.sql` como `view`;
- evitar preview completo no dbt Power User, porque consultar a view executa a deduplicacao pesada.

Importante: criar a view e leve, mas consultar a view pode ser pesado. Por isso `dbt run --select fct_trips` pode passar, enquanto visualizar `fct_trips` no dbt Power User pode voltar a gerar `Out of Memory`.

Opcoes futuras para resolver de forma definitiva:

- reduzir o volume processado em desenvolvimento com filtros de data;
- transformar `int_trips` em modelo incremental e processar por batches;
- usar um ambiente com mais memoria, como Codespaces ou BigQuery;
- revisar a estrategia de deduplicacao antes de materializar a tabela completa.
