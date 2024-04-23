drop table if exists x;
create table x (i int, j int) engine MergeTree order by i;
insert into x values (1, 2);

select toTypeName(tuple(i, j)) from x;
select tupleNames(tuple(i, j)) from x;

select tupleNames(1); -- { serverError 43 }

drop table x;
