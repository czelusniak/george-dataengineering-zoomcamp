{{
  config(materialized='table' )
}}

with unioned as (
    select * from {{ ref('int_trips_unioned') }}
),

payment_types as (
    select * from {{ ref('payment_type_lookup') }}
),

trip_events as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'u.vendor_id',
            'u.pickup_datetime',
            'u.pickup_location_id',
            'u.dropoff_datetime',
            'u.dropoff_location_id',
            'u.service_type'
        ]) }} as trip_id,

        u.*

    from unioned as u
),

trips as (
    select
        trip_id,

        -- The grain of this model is one row per logical trip.
        -- Some source rows share the same trip identity but have opposite financial signs,
        -- which looks like an original charge plus a refund/dispute adjustment.
        -- Instead of keeping an arbitrary row with row_number(), aggregate those events
        -- so the final trip keeps the net financial impact.
        any_value(vendor_id) as vendor_id,
        any_value(service_type) as service_type,
        any_value(rate_code_id) as rate_code_id,
        any_value(pickup_location_id) as pickup_location_id,
        any_value(dropoff_location_id) as dropoff_location_id,
        any_value(pickup_datetime) as pickup_datetime,
        any_value(dropoff_datetime) as dropoff_datetime,
        any_value(store_and_fwd_flag) as store_and_fwd_flag,
        any_value(passenger_count) as passenger_count,
        any_value(trip_distance) as trip_distance,
        any_value(trip_type) as trip_type,

        sum(fare_amount) as fare_amount,
        sum(extra) as extra,
        sum(mta_tax) as mta_tax,
        sum(tip_amount) as tip_amount,
        sum(tolls_amount) as tolls_amount,
        sum(ehail_fee) as ehail_fee,
        sum(improvement_surcharge) as improvement_surcharge,
        sum(total_amount) as total_amount,

        -- Use the payment type from the largest amount event as the representative
        -- payment type for the logical trip, usually the original positive charge.
        arg_max(coalesce(payment_type, 0), total_amount) as payment_type,

        count(*) as trip_event_count,
        sum(case when total_amount < 0 then 1 else 0 end) > 0 as has_negative_adjustment

    from trip_events
    group by trip_id
),

enriched as (
    select
        trips.*,
        coalesce(pt.description, 'Unknown') as payment_type_description

    from trips
    left join payment_types as pt
        on trips.payment_type = pt.payment_type
)

select * from enriched