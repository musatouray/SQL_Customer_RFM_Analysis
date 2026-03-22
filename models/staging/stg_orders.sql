-- models/staging/stg_orders.sql
-- Standardises raw orders before RFM calculations.
-- Replace `raw.orders` with your actual source table name.

with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        cast(order_id       as varchar(50))  as order_id,
        cast(customer_id    as varchar(50))  as customer_id,
        cast(order_date     as date)         as order_date,
        cast(order_amount   as decimal(18,2)) as order_amount
    from source
    where order_date is not null
      and customer_id is not null
      and order_amount > 0
)

select * from renamed
