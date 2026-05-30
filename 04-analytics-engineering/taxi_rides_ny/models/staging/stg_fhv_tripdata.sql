with source as (
    select * from {{ source('raw_data', 'fhv_tripdata') }}
),

renamed as (
    select
        cast(dispatching_base_num as string) as dispatching_base_num,
        cast(pulocationid as integer) as pickup_location_id,
        cast(dolocationid as integer) as dropoff_location_id,

        -- timestamps
        cast(pickup_datetime as timestamp) as pickup_datetime,
        cast(dropoff_datetime as timestamp) as dropoff_datetime,

        -- trip info
        cast(SR_Flag as integer) as sr_flag,
        cast(affiliated_base_number as string) as affiliated_base_number

    from source
    where dispatching_base_num is not null
    and pickup_datetime >= '2019-01-01' 
    and pickup_datetime < '2020-01-01'
)

select * from renamed

{% if target.name == 'dev' %}
where pickup_datetime >= '{{ var("dev_start_date") }}'
  and pickup_datetime < '{{ var("dev_end_date") }}'
{% endif %}