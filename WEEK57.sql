with step_one as (
    select 1 as numone,
            2 as numtwo,
            3 as numthree,
            'a' as letterone,
            'b' as lettertwo,
            'c' as letterthree,
            '+' as symbolone,
            '#' as symboltwo,
            ';' as symbolthree
)
select * ilike '%two'
from step_one
