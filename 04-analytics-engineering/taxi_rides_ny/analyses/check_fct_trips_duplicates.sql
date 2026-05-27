select 
    trip_id,
    count(*) as count_duplicates 
from {{ ref('fct_trips') }}
where pickup_datetime >= '2019-01-01'
and pickup_datetime < '2019-02-01'
group by trip_id
having count(*) > 1
;
