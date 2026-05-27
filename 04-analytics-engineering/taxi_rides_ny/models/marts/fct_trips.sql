{{ config(materialized='view') }}

/*
To Do:
- One row per trip (doesn't matter if yellow or green)
- Add a primary key (trip_id). It has to be unique.
- Find all the duplicates, understand why they happen, and fix them.
- Find a way to enrich the column payment_type.
*/

with trips as (
    select * from {{ ref('int_trips') }}
)

select * from trips

