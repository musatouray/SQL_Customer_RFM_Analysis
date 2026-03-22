-- models/marts/rfm_scores.sql
-- Calculates Recency, Frequency, and Monetary values per customer,
-- then assigns a 1-5 score for each dimension using NTILE windows.

with orders as (
    select * from {{ ref('stg_orders') }}
),

-- Latest order date in the dataset is used as the reference point
snapshot_date as (
    select max(order_date) as max_date from orders
),

rfm_raw as (
    select
        o.customer_id,
        datediff(day, max(o.order_date), s.max_date) as recency_days,
        count(distinct o.order_id)                   as frequency,
        sum(o.order_amount)                          as monetary
    from orders         as o
    cross join snapshot_date as s
    group by o.customer_id, s.max_date
),

rfm_scored as (
    select
        customer_id,
        recency_days,
        frequency,
        monetary,
        -- Lower recency_days = more recent = higher score
        ntile(5) over (order by recency_days asc)  as recency_score,
        ntile(5) over (order by frequency asc)     as frequency_score,
        ntile(5) over (order by monetary asc)      as monetary_score
    from rfm_raw
)

select
    customer_id,
    recency_days,
    frequency,
    round(monetary, 2)                                        as monetary,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score          as rfm_total_score
from rfm_scored
