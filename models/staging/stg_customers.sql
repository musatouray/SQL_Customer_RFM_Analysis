-- models/staging/stg_customers.sql
-- Standardises raw customer records.
-- Replace `raw.customers` with your actual source table name.

with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        cast(customer_id    as varchar(50))  as customer_id,
        cast(customer_name  as varchar(255)) as customer_name,
        cast(email          as varchar(255)) as email,
        cast(signup_date    as date)         as signup_date
    from source
    where customer_id is not null
)

select * from renamed
