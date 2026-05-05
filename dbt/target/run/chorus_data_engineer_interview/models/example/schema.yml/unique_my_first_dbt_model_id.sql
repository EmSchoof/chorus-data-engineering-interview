
  create view "postgres"."public"."unique_my_first_dbt_model_id__dbt_tmp"
    
    
  as (
    select
    id as unique_field,
    count(*) as n_records

from "postgres"."public"."my_first_dbt_model"
where id is not null
group by id
having count(*) > 1
  );