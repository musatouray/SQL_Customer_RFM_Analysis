-- models/marts/customer_segments.sql
-- Joins RFM scores with customer details and assigns a human-readable segment.

with rfm as (
    select * from {{ ref('rfm_scores') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

segmented as (
    select
        r.customer_id,
        c.customer_name,
        c.email,
        r.recency_days,
        r.frequency,
        r.monetary,
        r.recency_score,
        r.frequency_score,
        r.monetary_score,
        r.rfm_total_score,
        case
            -- Champions: bought recently, often and spend the most
            when r.recency_score = 5 and r.frequency_score = 5 and r.monetary_score = 5
                then 'Champion'
            -- Loyal Customers: buy regularly
            when r.frequency_score >= 4 and r.monetary_score >= 4
                then 'Loyal Customer'
            -- Potential Loyalists: recent but low frequency
            when r.recency_score >= 4 and r.frequency_score < 3
                then 'Potential Loyalist'
            -- Recent Customers: bought recently for the first time
            when r.recency_score = 5 and r.frequency_score = 1
                then 'New Customer'
            -- Promising: recent with average spending
            when r.recency_score >= 4 and r.frequency_score = 2
                then 'Promising'
            -- Need Attention: above average recency/frequency/monetary but not recent
            when r.recency_score = 3 and r.frequency_score >= 3 and r.monetary_score >= 3
                then 'Need Attention'
            -- About to Sleep: below average recency/frequency
            when r.recency_score <= 2 and r.frequency_score <= 2
                then 'About To Sleep'
            -- At Risk: spent big but not visited recently
            when r.recency_score <= 2 and r.frequency_score >= 4 and r.monetary_score >= 4
                then 'At Risk'
            -- Cannot Lose Them: made big purchases and bought often, but not recently
            when r.recency_score = 1 and r.frequency_score = 5 and r.monetary_score = 5
                then 'Cannot Lose Them'
            -- Hibernating: last purchase was long ago, low orders and spenders
            when r.recency_score <= 2 and r.frequency_score <= 3 and r.monetary_score <= 3
                then 'Hibernating'
            -- Lost: lowest recency, frequency and monetary
            when r.rfm_total_score <= 4
                then 'Lost'
            else 'Other'
        end as customer_segment
    from rfm      as r
    left join customers as c on r.customer_id = c.customer_id
)

select * from segmented
