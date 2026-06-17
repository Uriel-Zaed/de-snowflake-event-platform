{% snapshot products_snapshot %}

{{
    config(
        target_database='EVENT_PLATFORM',
        target_schema='DBT_SNAPSHOTS',
        unique_key='product_id',
        strategy='timestamp',
        updated_at='catalog_updated_at'
    )
}}

SELECT
    product_id,
    product_name,
    category,
    brand,
    base_price,
    is_active,
    catalog_updated_at AS catalog_updated_at
FROM {{ ref('products') }}

{% endsnapshot %}