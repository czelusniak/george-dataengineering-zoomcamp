with taxi_zone_lookup as (
    select * from {{ ref('taxi_zone_lookup')}}
),

renamed as (
    select
        location_id as location_id,
        borough,
        zone,
        service_zone
    from taxi_zone_lookup
)


select * from taxi_zone_lookup