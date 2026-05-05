
  create view "postgres"."public"."not_null_my_first_dbt_model_id__dbt_tmp"
    
    
  as (
    select id
from "postgres"."public"."my_first_dbt_model"
where id is null
  );