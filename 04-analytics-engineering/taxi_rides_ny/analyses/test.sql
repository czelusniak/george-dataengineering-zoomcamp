select *
from dev.fct_trips
where pickup_datetime >= '2019-01-01'
and pickup_datetime < '2019-01-08'
limit 100