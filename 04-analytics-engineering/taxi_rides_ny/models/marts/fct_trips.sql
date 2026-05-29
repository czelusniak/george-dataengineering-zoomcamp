{{
  config(
    materialized='incremental',
    unique_key='trip_id',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'  )
}}

with trips as (
    select * from {{ ref('int_trips') }}
),

zones as (
    select * from {{ ref('dim_zones') }}
),

trips_with_zones as (
    select
        trips.trip_id,
        trips.vendor_id,
        trips.service_type,
        trips.rate_code_id,

        trips.pickup_location_id,
        pickup_zones.borough as pickup_borough,
        pickup_zones.zone as pickup_zone,
        trips.dropoff_location_id,
        dropoff_zones.borough as dropoff_borough,
        dropoff_zones.zone as dropoff_zone,

        trips.pickup_datetime,
        trips.dropoff_datetime,
        trips.store_and_fwd_flag,

        trips.passenger_count,
        trips.trip_distance,
        trips.trip_type,
        {{ get_trip_duration_minutes('trips.pickup_datetime', 'trips.dropoff_datetime') }} as trip_duration_minutes,

        trips.fare_amount,
        trips.extra,
        trips.mta_tax,
        trips.tip_amount,
        trips.tolls_amount,
        trips.ehail_fee,
        trips.improvement_surcharge,
        trips.total_amount,
        trips.payment_type,
        trips.payment_type_description,
        trips.trip_event_count,
        trips.has_negative_adjustment

    from trips
    left join zones as pickup_zones
        on trips.pickup_location_id = pickup_zones.location_id
    left join zones as dropoff_zones
        on trips.dropoff_location_id = dropoff_zones.location_id
)

select * from trips_with_zones

{% if is_incremental() %}
where pickup_datetime > (select max(pickup_datetime) from {{ this }})
{% endif %}