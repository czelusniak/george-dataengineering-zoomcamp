# Module 2 — Workflow Orchestration

**Tools:** Kestra, Data Lakes

---

## Workflow Orchestration

Coordenar a execução de tarefas em uma pipeline de dados: definir ordem, dependências, agendamento e tratamento de falhas.

**Exemplo:** ingerir dados de uma API → limpar → carregar no warehouse → notificar. Sem orquestração, você roda cada etapa manualmente. Com orquestração, tudo acontece automaticamente na ordem certa.

---

## Kestra

Orquestrador de workflows open-source. Workflows são definidos em YAML e podem disparar containers, scripts Python, queries SQL, chamadas de API, etc.

**Diferença para outros orquestradores:**

| | Kestra | Airflow | Prefect |
|---|---|---|---|
| Definição | YAML | Python | Python |
| UI | completa, moderna | básica | moderna |
| Curva de aprendizado | baixa | alta | média |
| Deploy | simples (Docker) | complexo | médio |

Airflow é o mais usado em produção mas exige mais conhecimento para configurar. Kestra é mais acessível para quem está começando.

---

## Containers do módulo 2

**`kestra_postgres`** — banco de dados interno do Kestra. Armazena os workflows, execuções e logs. O Kestra precisa de um banco para persistir estado entre restarts.

**`kestra`** — a aplicação do Kestra em si. Expõe a UI na porta 8080 e a API na 8081. Roda como root para poder criar containers Docker ao executar tarefas.

---

## Data Lakes

<!-- notas aqui -->
