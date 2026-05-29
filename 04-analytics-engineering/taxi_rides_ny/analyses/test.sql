select *
from {{ ref('int_trips') }}
;

select *
from {{ ref('fct_trips') }}
;

select *
from {{ ref('dim_zones') }}
;



select
    max(pickup_datetime) as max_pickup_datetime,
    min(pickup_datetime) as min_pickup_datetime,
    count(*) as rows
from dev.fct_trips;


select
    max(pickup_datetime) as max_pickup_datetime,
    min(pickup_datetime) as min_pickup_datetime,
    count(*) as rows
from prod.fct_trips;

select
    min(pickup_datetime) as min_pickup,
    max(pickup_datetime) as max_pickup
from prod.int_trips_unioned;

select
    min(pickup_datetime) as min_pickup,
    max(pickup_datetime) as max_pickup
from prod.int_trips_unioned
where pickup_datetime >= '2019-01-01'
and pickup_datetime < '2022-01-01';


select
    count(*) as rows,
    count(distinct trip_id) as distinct_trip_ids,
    min(pickup_datetime) as min_pickup,
    max(pickup_datetime) as max_pickup
from prod.int_trips;




-- checking
select
    'incremental' as strategy,
    count(*) as rows,
    count(distinct trip_id) as distinct_trip_ids,
    min(pickup_datetime) as min_pickup,
    max(pickup_datetime) as max_pickup
from prod.int_trips

union all

select
    'full_refresh_check' as strategy,
    count(*) as rows,
    count(distinct trip_id) as distinct_trip_ids,
    min(pickup_datetime) as min_pickup,
    max(pickup_datetime) as max_pickup
from prod.int_trips_full_refresh_check;


--Trips que existem no incremental e não existem no full:
select count(*) as missing_in_full
from (
    select trip_id
    from prod.int_trips

    except

    select trip_id
    from prod.int_trips_full_refresh_check
);

--Trips que existem no full e não existem no incremental:
select count(*) as missing_in_incremental
from (
    select trip_id
    from prod.int_trips_full_refresh_check

    except

    select trip_id
    from prod.int_trips
);


  select
      min(pickup_datetime) as min_pickup,
      max(pickup_datetime) as max_pickup
  from prod.int_trips;

    select
      year(pickup_datetime) as pickup_year,
      count(*) as rows
  from prod.int_trips_full_refresh_check
  where trip_id not in (
      select trip_id from prod.int_trips
  )
  group by 1
  order by 1;