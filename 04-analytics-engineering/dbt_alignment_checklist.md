# Checklist de alinhamento com a referencia dbt do curso

Objetivo: alinhar o projeto `taxi_rides_ny` com a estrutura da referencia em `course-materials/04-analytics-engineering/taxi_rides_ny`, antes de evoluir o `fct_trips.sql`.

## Onde o projeto esta em relacao a referencia

O projeto ja passou da configuracao inicial e concluiu a principal etapa de alinhamento de staging, intermediate e marts em `dev`.

Ja existe:

- `packages.yml` com `dbt_utils` e `codegen`;
- modelos em `staging`, `intermediate` e `marts`;
- seeds para `payment_type_lookup` e `taxi_zone_lookup`;
- configuracao de materializacao por camada no `dbt_project.yml`, seguindo a referencia sem `+schema` por camada;
- filtro de desenvolvimento nos modelos de staging usando `target.name == 'dev'` e vars;
- `models/intermediate/schema.yml` com testes para o grao de `int_trips`;
- `models/marts/schema.yml` com testes de chaves, valores aceitos e relacionamentos;
- macro `get_trip_duration_minutes`;
- `fct_trips` incremental, enriquecido com `dim_zones` e duracao da viagem;
- uma decisao propria em `int_trips.sql` para consolidar eventos financeiros por `trip_id`.

A diferenca mais importante em relacao a referencia e que a referencia usa deduplicacao simples com `qualify row_number()`, enquanto este projeto investigou duplicatas e encontrou linhas positivas/negativas para a mesma viagem. Por isso, a consolidacao com `group by trip_id` deve ser tratada como um desvio consciente, nao como uma etapa faltando.

## Engenharia reversa da referencia

### `dbt_project.yml`

A referencia define variaveis para amostragem em desenvolvimento:

```yaml
vars:
  dev_start_date: '2019-01-01'
  dev_end_date: '2019-02-01'
```

Tambem configura materializacoes por camada:

```yaml
models:
  taxi_rides_ny:
    staging:
      +materialized: view
    intermediate:
      +materialized: table
    marts:
      +materialized: table
```

Neste projeto, foi decidido seguir a referencia e nao separar schemas por camada no `dbt_project.yml`:

```yaml
models:
  taxi_rides_ny:
    staging:
      +materialized: view
    intermediate:
      +materialized: table
    marts:
      +materialized: table
```

Com `schema: dev` no target `dev`, os modelos sao criados diretamente em `dev`. Com `schema: prod` no target `prod`, os modelos sao criados diretamente em `prod`. Os schemas antigos `dev_staging` e `prod_staging`, criados durante um experimento com `+schema`, foram removidos do DuckDB.

### Filtro de desenvolvimento

Na referencia, o bloco abaixo aparece nos modelos de `staging`, nao em `marts`:

```sql
{% if target.name == 'dev' %}
where pickup_datetime >= '2019-01-01' and pickup_datetime < '2019-02-01'
{% endif %}
```

Ele aparece em:

- `models/staging/stg_green_tripdata.sql`;
- `models/staging/stg_yellow_tripdata.sql`.

Essa escolha e importante: filtrar cedo reduz o volume de dados para todos os modelos downstream. Se o filtro fosse colocado apenas em `fct_trips`, os modelos intermediarios ainda poderiam processar o dataset completo antes de o limite ser aplicado.

Melhoria recomendada para aprendizado: usar as variaveis do `dbt_project.yml` em vez de datas fixas no SQL.

Exemplo desejado:

```sql
{% if target.name == 'dev' %}
where pickup_datetime >= '{{ var("dev_start_date") }}'
  and pickup_datetime < '{{ var("dev_end_date") }}'
{% endif %}
```

### `staging`

A referencia usa `staging` para:

- ler das fontes raw;
- padronizar nomes de colunas;
- fazer casts;
- filtrar `vendorid is not null`;
- aplicar filtro de data apenas no target `dev`.

Neste projeto, `stg_yellow_tripdata.sql` tambem adiciona `trip_type` e `ehail_fee` ja no staging. A referencia faz essa normalizacao em `int_trips_unioned.sql`. As duas abordagens funcionam, mas e importante documentar a decisao:

- referencia: staging fica mais proximo da fonte; normalizacao entre yellow/green acontece em intermediate;
- projeto atual: staging ja entrega yellow e green com schema mais compativel.

### `intermediate`

A referencia usa:

- `int_trips_unioned.sql` para unir yellow e green em um schema comum;
- `int_trips.sql` para gerar `trip_id`, enriquecer `payment_type` e deduplicar com `row_number()`.

Neste projeto, `int_trips.sql` ja foi alem da referencia:

- gera `trip_id` com mais campos;
- agrupa por `trip_id`;
- soma valores financeiros;
- escolhe `payment_type` representativo;
- adiciona `trip_event_count` e `has_negative_adjustment`.

Essa diferenca deve ser mantida por enquanto, porque resolve um problema observado nos dados e evita descartar arbitrariamente linhas de ajuste financeiro.

### `marts`

A referencia tem um `fct_trips.sql` mais completo:

- materializado como incremental;
- usa `unique_key='trip_id'`;
- faz joins com `dim_zones`;
- adiciona campos como `pickup_borough`, `pickup_zone`, `dropoff_borough`, `dropoff_zone`;
- calcula `trip_duration_minutes` usando macro;
- usa `is_incremental()` para processar apenas viagens novas.

Neste projeto, `fct_trips.sql` ja foi alinhado com a referencia na parte principal:

- materializado como incremental em `dev`;
- usa `unique_key='trip_id'`;
- faz joins com `dim_zones`;
- adiciona `pickup_borough`, `pickup_zone`, `dropoff_borough` e `dropoff_zone`;
- calcula `trip_duration_minutes` com macro;
- usa `is_incremental()` para processar apenas viagens novas.

O projeto ainda preserva campos proprios da consolidacao:

- `trip_event_count`;
- `has_negative_adjustment`.

## Ordem de prioridade/aprendizagem

1. Confirmar dependencias do projeto

   Verificar que `taxi_rides_ny/packages.yml` contem as dependencias usadas na referencia:

   - `dbt-labs/dbt_utils`
   - `dbt-labs/codegen`

   Isso permite usar macros como `dbt_utils.generate_surrogate_key()`. Concluido.

2. Adicionar variaveis de desenvolvimento no `dbt_project.yml`

   Adicionar:

   ```yaml
   vars:
     dev_start_date: '2019-01-01'
     dev_end_date: '2019-02-01'
   ```

   Objetivo de aprendizado: entender como configuracoes do projeto podem ser usadas dentro dos modelos com `var()`.

   Concluido.

3. Implementar filtro de dev em `staging`

   Adicionar o bloco `{% if target.name == 'dev' %}` em:

   - `models/staging/stg_green_tripdata.sql`;
   - `models/staging/stg_yellow_tripdata.sql`.

   Preferir usar `var("dev_start_date")` e `var("dev_end_date")` em vez de datas fixas.

   Motivo: filtrar cedo reduz o volume processado por `intermediate` e `marts`.

   Concluido e validado em `dev`.

4. Revisar sources sem copiar cegamente a referencia

   A referencia usa `source('raw', ...)`; este projeto usa `source('raw_data', ...)`.

   Prioridade: manter consistente com o ambiente local/DuckDB e com `models/staging/_sources.yml`.

   Concluido mantendo `source('raw_data', ...)`.

5. Consolidar a decisao de normalizacao entre yellow e green

   A referencia preenche `trip_type` e `ehail_fee` em `int_trips_unioned.sql`.

   Este projeto ja faz parte disso em `stg_yellow_tripdata.sql`:

   - `trip_type = 1`;
   - `ehail_fee = 0`.

   Escolher uma abordagem e manter consistente. Para aprendizado, a abordagem da referencia mostra melhor o papel do intermediate; a abordagem atual deixa staging mais padronizado.

   Decisao atual: manter a normalizacao parcial no staging para preservar a estrutura ja aprendida.

6. Alinhar ou revisar `int_trips_unioned.sql`

   Atualizar `models/intermediate/int_trips_unioned.sql` para:

   - selecionar colunas explicitamente em vez de `select *`;
   - normalizar o schema entre green e yellow taxi;
   - usar `Green` e `Yellow` em `service_type`;
   - preencher campos que existem em apenas um tipo de taxi, como `trip_type` e `ehail_fee`.

   Concluido e validado em `dev`.

7. Manter a estrategia propria em `int_trips.sql`

   A referencia deduplica com `qualify row_number()`, mas este projeto encontrou eventos financeiros positivos/negativos para a mesma viagem.

   Portanto, por enquanto, manter a estrategia atual:

   - ler de `int_trips_unioned`;
   - gerar `trip_id`;
   - enriquecer `payment_type` com uma descricao;
   - consolidar eventos com `group by trip_id`;
   - somar campos financeiros;
   - preservar indicadores como `trip_event_count` e `has_negative_adjustment`.

   Concluido e validado em `dev`.

8. Evoluir `fct_trips.sql`

   Concluido em `dev`:

   - le de `{{ ref('int_trips') }}`;
   - faz joins com `dim_zones` para pickup e dropoff;
   - adiciona `pickup_borough`, `pickup_zone`, `dropoff_borough`, `dropoff_zone`;
   - adiciona `trip_duration_minutes`;
   - materializa como incremental com `unique_key='trip_id'`.

9. Criar ou revisar macros

   A referencia tem:

   - `safe_cast`;
   - `get_vendor_data`;
   - `get_trip_duration_minutes`;
   - `macros_properties.yml`.

   O projeto atual tem `get_vendor_names` e `get_trip_duration_minutes`.

   Concluido para a macro usada por `fct_trips`. `macros_properties.yml` ainda pode ser revisado futuramente para documentacao.

10. Criar ou revisar `models/intermediate/schema.yml`

   Documentar e testar os modelos intermediarios conforme a estrategia atual:

   - `int_trips_unioned`;
   - `int_trips`;
   - `trip_id` com `unique` e `not_null`;
   - `service_type` com valores aceitos `Green` e `Yellow`;
   - campos essenciais como `vendor_id`, `pickup_datetime` e `total_amount`.

   Concluido e validado em `dev`.

11. Criar ou revisar `models/marts/schema.yml`

   Documentar e testar os marts principais:

   - `dim_zones`;
   - `dim_vendors`;
   - `dim_payment_type`, se mantida;
   - `fct_trips`.

   Concluido e validado em `dev`.

12. Pensar em incremental somente depois do mart estar estavel

   A referencia materializa `fct_trips` como incremental. Esta etapa foi concluida para `fct_trips` em `dev` depois de estabilizar:

   - o grao de `int_trips`;
   - os joins de zonas;
   - os testes;
   - o filtro de dev em staging.

13. Rodar validacoes

   Depois dos ajustes, executar:

   ```bash
   dbt deps
   dbt seed
   dbt run --select int_trips_unioned int_trips fct_trips
   dbt test --select int_trips fct_trips
   ```

   Validacao atual: `dbt build --select +fct_trips --target dev` passou.

## Estado atual em `dev`

Atualizado em 2026-05-29.

- `dev.stg_green_tripdata` e `dev.stg_yellow_tripdata`: views filtradas para janeiro de 2019.
- `dev.int_trips_unioned`: tabela com green + yellow normalizados.
- `dev.int_trips`: tabela com uma linha por viagem logica consolidada.
- `dev.fct_trips`: tabela incremental com zonas, duracao da viagem e campos de consolidacao.
- `dev.fct_trips` validado com:
  - `8.288.993` linhas;
  - `8.288.993` `trip_id` distintos;
  - janela de `2019-01-01` a `2019-01-31`;
  - `dbt build --select +fct_trips --target dev` concluido com sucesso.

## Proximas etapas recomendadas

1. Gerar e revisar documentacao dbt local:

   ```bash
   ../.venv/bin/dbt docs generate --target dev
   ```

   Objetivo: visualizar lineage, descricoes, testes e colunas no dbt Power User/docs.

   Concluido: `dbt docs generate --target dev` passou e escreveu `target/catalog.json`.

2. Revisar macros/documentacao:

   - considerar criar `macros/macros_properties.yml`;
   - documentar `get_trip_duration_minutes`;
   - decidir se `get_vendor_names` deve ser mantida como macro propria ou alinhada com `get_vendor_data` da referencia.

   Concluido: `macros/macros_properties.yml` documenta `get_trip_duration_minutes` e `get_vendor_names`; `dbt docs generate --target dev` passou depois da alteracao.

3. Decidir estrategia para `prod`:

   - testar staging, intermediate e marts em `prod`;
   - validar `int_trips` incremental contra uma tabela full refresh de comparacao;
   - materializar `fct_trips` em `prod` depois de estabilizar `int_trips`.

   Concluido:

   - `stg_green_tripdata` e `stg_yellow_tripdata` existem em `prod` como views, e `dbt test --select stg_green_tripdata stg_yellow_tripdata --target prod` passou;
   - `prod.int_trips_unioned` foi materializado e testado com sucesso;
   - `prod.int_trips` foi materializado incrementalmente por batches;
   - `prod.int_trips_full_refresh_check` foi criado como tabela de comparacao full refresh;
   - depois de rodar os batches faltantes, `prod.int_trips` e `prod.int_trips_full_refresh_check` passaram a ter o mesmo conjunto de `trip_id`.
   - `prod.dim_zones`, `prod.dim_vendors` e `prod.dim_payment_type` foram materializados com sucesso;
   - `prod.fct_trips` foi materializado como incremental;
   - `dbt test --select dim_zones dim_vendors dim_payment_type fct_trips --target prod` passou com `20/20`.

   Volume observado em `prod.int_trips_unioned`:

   - `Green`: `6.835.902` linhas;
   - `Yellow`: `107.991.349` linhas.

   Resultado do experimento:

   - memoria nao voltou a ser bloqueio observado;
   - o usuario praticou materializacao incremental em `int_trips`;
   - `int_trips_full_refresh_check` sera mantido no projeto como artefato de validacao/aprendizado.

## Divisao de responsabilidade por camada

- `staging`: limpa e padroniza nomes/tipos vindos das fontes raw.
- `intermediate/int_trips_unioned`: une green e yellow taxi em um schema comum.
- `intermediate/int_trips`: gera chave, enriquece pagamento e remove duplicatas.
- `marts/fct_trips`: tabela fato final para analise, com joins de dimensoes.

## Nota sobre memoria no DuckDB

Durante uma etapa anterior de deduplicacao em `int_trips.sql`, o comando abaixo podia falhar com `Out of Memory`:

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

Decisao temporaria tomada na epoca:

- manter `models/intermediate/int_trips.sql` como `view`;
- manter `models/marts/fct_trips.sql` como `view`;
- evitar preview completo no dbt Power User, porque consultar a view executa a deduplicacao pesada.

Importante: naquela etapa, criar a view era leve, mas consultar a view podia ser pesado. Por isso `dbt run --select fct_trips` podia passar, enquanto visualizar `fct_trips` no dbt Power User podia voltar a gerar `Out of Memory`.

Opcoes futuras para resolver de forma definitiva:

- reduzir o volume processado em desenvolvimento com filtros de data;
- transformar `int_trips` em modelo incremental e processar por batches;
- usar um ambiente com mais memoria, como Codespaces ou BigQuery;
- revisar a estrategia de deduplicacao antes de materializar a tabela completa.

Atualizacao em 2026-05-29:

- Depois da troca da estrategia de deduplicacao para consolidacao com `group by trip_id` e do uso de filtro em `dev`, os problemas de memoria nao se repetiram.
- Memoria nao esta mais sendo tratada como bloqueio atual.
- O usuario quer seguir explorando materializacao incremental por aprendizado.
- `int_trips` e `fct_trips` deixaram de usar a materializacao temporaria como `view` e foram evoluidos para incremental no fluxo atual.

## Atualizacao: decisao de deduplicacao em `int_trips`

Data da decisao: 2026-05-28.

Contexto:

- O objetivo de grao para `int_trips`/`fct_trips` e `one row per trip`, independente de ser taxi `Green` ou `Yellow`.
- O volume observado no DuckDB local foi aproximadamente:
  - `dev.stg_yellow_tripdata`: `107.991.349` linhas;
  - `dev.stg_green_tripdata`: `6.835.902` linhas;
  - `dev.int_trips_unioned`: `114.827.251` linhas.
- Esse volume e basicamente a soma de yellow + green depois do filtro `vendorid is not null`; portanto os `~114M` nao sao, por si so, evidencia de duplicacao indevida.
- A query `taxi_rides_ny/analyses/check_fct_trips_duplicates.sql` foi usada para investigar `trip_id` duplicado em janeiro de 2019.

Achado principal:

- As linhas com mesmo `trip_id` nao eram duplicatas identicas.
- A diferenca estava principalmente em campos financeiros, como:
  - `fare_amount`;
  - `mta_tax`;
  - `improvement_surcharge`;
  - `total_amount`.
- Em varios casos, os valores tinham apenas sinal oposto, por exemplo uma linha positiva e outra negativa.
- Tambem havia diferenca em `payment_type`/`payment_type_description`, sugerindo que algumas linhas negativas representam ajuste, retorno, void ou dispute da viagem original.

Decisao tomada:

- Nao usar a estrategia simples da referencia com `qualify row_number()` como solucao final.
- Motivos:
  - `row_number()` escolheria uma linha arbitraria e descartaria a outra;
  - descartar a linha positiva ou negativa pode distorcer receita;
  - no DuckDB local/WSL, `row_number()` sobre `~114M` linhas ja havia causado erro de memoria;
  - semanticamente, essas linhas parecem eventos financeiros da mesma viagem, nao duplicatas simples.
- Em vez disso, `models/intermediate/int_trips.sql` foi alterado para consolidar uma linha por viagem com `group by trip_id`.

Implementacao atual em `models/intermediate/int_trips.sql`:

- `trip_id` representa a viagem logica e e gerado com:

  ```sql
  vendor_id,
  pickup_datetime,
  pickup_location_id,
  dropoff_datetime,
  dropoff_location_id,
  service_type
  ```

- Campos financeiros sao agregados com `sum()`, por exemplo:

  ```sql
  sum(fare_amount) as fare_amount,
  sum(mta_tax) as mta_tax,
  sum(improvement_surcharge) as improvement_surcharge,
  sum(total_amount) as total_amount
  ```

- Campos descritivos/atributos da viagem usam `any_value()`, assumindo que sao iguais dentro do mesmo `trip_id`, por exemplo:

  ```sql
  any_value(vendor_id) as vendor_id,
  any_value(service_type) as service_type,
  any_value(pickup_datetime) as pickup_datetime
  ```

- `payment_type` representativo e escolhido com:

  ```sql
  arg_max(coalesce(payment_type, 0), total_amount) as payment_type
  ```

  Isso tende a escolher o tipo de pagamento da linha com maior valor, normalmente a cobranca positiva original.

- Foram adicionadas colunas auxiliares:

  ```sql
  count(*) as trip_event_count,
  sum(case when total_amount < 0 then 1 else 0 end) > 0 as has_negative_adjustment
  ```

  `trip_event_count` mostra quantos registros originais foram consolidados naquela viagem.
  `has_negative_adjustment` indica se a viagem teve algum evento financeiro negativo.

Exemplo conceitual:

Antes da consolidacao:

```text
trip_id | fare_amount | mta_tax | total_amount | payment_type
abc     |  18.00      |  0.50   |  20.00       | 1
abc     | -18.00      | -0.50   | -20.00       | 6
```

Depois da consolidacao:

```text
trip_id | fare_amount | mta_tax | total_amount | payment_type | trip_event_count | has_negative_adjustment
abc     |   0.00      |  0.00   |   0.00       | 1            | 2                | true
```

Validacoes ja executadas:

```bash
cd /home/ygritte/dev/de-zoomcamp-2k26/george-dataengineering-zoomcamp/04-analytics-engineering/taxi_rides_ny
../.venv/bin/dbt compile --select int_trips
../.venv/bin/dbt run --select int_trips
```

Resultado:

- `dbt compile --select int_trips`: passou.
- `dbt run --select int_trips`: passou porque o modelo ainda estava configurado como `view`.
- Checagem de janeiro de 2019 na view nova:

  ```text
  rows_jan:          8.288.993
  distinct_trip_ids: 8.288.993
  duplicate_rows:    0
  ```

Observacao sobre materializacao:

- No momento da alteracao, `models/intermediate/int_trips.sql` ainda tinha:

  ```sql
  {{ config(materialized='view') }}
  ```

- Se essa linha for removida, o modelo passa a seguir `dbt_project.yml`, onde `intermediate` esta configurado como `table`.
- Isso alinha melhor com a referencia do curso, mas o DuckDB precisara executar e salvar o `group by` sobre o volume completo.
- Se houver `Out of Memory`, voltar temporariamente para `view` ou implementar uma estrategia incremental/por batches.

Proximos passos recomendados:

1. Decidir se `int_trips` deve continuar como `view` ou virar `table`.
2. Se for virar `table`, remover `{{ config(materialized='view') }}` de `models/intermediate/int_trips.sql` e rodar:

   ```bash
   ../.venv/bin/dbt run --select int_trips
   ```

3. Se passar, rodar:

   ```bash
   ../.venv/bin/dbt run --select fct_trips
   ```

4. Criar ou atualizar `models/intermediate/schema.yml` com testes para:

   - `int_trips.trip_id`: `unique` e `not_null`;
   - `int_trips.service_type`: accepted values `Green` e `Yellow`;
   - campos essenciais como `pickup_datetime` e `total_amount`.

5. Rodar:

   ```bash
   ../.venv/bin/dbt test --select int_trips
   ```

6. Considerar uma modelagem futura com dois graos separados:

   - `int_trip_events`: uma linha por evento financeiro original;
   - `int_trips`: uma linha por viagem logica consolidada.

   Essa separacao deixaria explicito que cobrancas, disputas e ajustes financeiros sao eventos, enquanto `int_trips` e a tabela consolidada no grao de viagem.
