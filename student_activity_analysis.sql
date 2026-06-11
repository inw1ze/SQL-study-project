-- 1. Основные данные студентов клиента 1
with first_data_users as (
    select
        u.id,
        u.username,
        u.company_id,
        concat_ws(' ', u.first_name, u.last_name) full_name,
        c.problem_id,
        c.is_false
    from users u
    left join codesubmit c on u.id = c.user_id
    where u.company_id = 1
),

-- 2. Информация по решению задач для каждого студента клиента 1
data_resh as (
    select
        f.id,
        case
            when full_name is null or full_name = '' then username
            else full_name
        end as "Имя",
        count(c.id) "Кол-во прокруток запроса",
        count(case when is_false = 1 then 1 end) "Кол-во неправильно решенных задач",
        count(case when is_false = 0 then 1 end) "Кол-во правильно решенных задач",
        round(count(case when is_false = 0 then 1 end) * 100.0 / nullif(count(c.id), 0), 2) "% Правильно решенных задач"
    from first_data_users f
    left join coderun c on c.user_id = f.id
    group by "Имя", f.id
    order by "% Правильно решенных задач" desc
),

-- 3. Топ 5 месяцев по количеству активности студентов клиента 1
activ_date as (
    select
        ROW_NUMBER() OVER (ORDER BY count(distinct u.user_id) DESC) AS n,
        to_char(entry_at, 'YYYY-MM') mons,
        count(distinct u.user_id) act_cnt
    from userentry u
    join users u2 on u2.id = u.user_id
    where u2.company_id = 1
    group by to_char(entry_at, 'YYYY-MM')
    order by act_cnt desc
    limit 5
),

-- 4. Топ 5 задач по ошибкам
zad_error as (
    select
        ROW_NUMBER() OVER (ORDER BY count(case when is_false = 1 then 1 end) DESC) AS n,
        problem_id,
        count(case when is_false = 1 then 1 end) cnt_error
    from codesubmit c
    join users u on u.id = c.user_id
    where company_id = 1
    group by problem_id
    order by cnt_error desc
    limit 5
),

-- 5. Топ 5 студентов по правильности решения
data_resh_5 as (
    select
        ROW_NUMBER() OVER (ORDER BY "% Правильно решенных задач" DESC) n,
        "Имя",
        "% Правильно решенных задач"
    from data_resh
    where "% Правильно решенных задач" is not null
    and "% Правильно решенных задач" < 100
    limit 5
)

-- Финальный запрос
select
    "Имя",
    "% Правильно решенных задач",
    problem_id "ID задачи",
    cnt_error "Количество ошибок в задаче",
    mons "Месяц",
    act_cnt "Количество заходов уникальных пользователей"
from data_resh_5 d
full join zad_error z on z.n = d.n
full join activ_date a on a.n = d.n
