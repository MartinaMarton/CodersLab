-- 1)Write a query that prepares a summary of the granted loans in the following dimensions:
-- a)year, quarter, month,
-- b)year, quarter,
-- c)year,
-- d)total.
-- Display the following information as the result of the summary:total amount of loans, average loan amount,total number of given loans.
-- 1A
select
    extract(year from date) as year,
    extract(quarter from date) as quarter,
    extract(month from date) as month,
    sum(amount) as total_amount_of_loans,
    avg(amount) as average_loan_amount,
    count(loan_id) as toal_number_of_given_loans
from loan
group by year, quarter,month
order by year, quarter, month;
-- 1B
select
    extract(quarter from date) as quarter,
    extract(month from date) as month,
    sum(amount) as total_amount_of_loans,
    avg(amount) as average_loan_amount,
    count(loan_id) as toal_number_of_given_loans
from loan
group by quarter,month
order by quarter, month;
-- 1C
select
    extract(month from date) as month,
    sum(amount) as total_amount_of_loans,
    avg(amount) as average_loan_amount,
    count(loan_id) as toal_number_of_given_loans
from loan
group by month
order by month;
-- 1D
select
    sum(amount) as total_amount_of_loans,
    avg(amount) as average_loan_amount,
    count(loan_id) as toal_number_of_given_loans
from loan;

-- 2) Loan Status (which status represent repaid loans (606) and which represent unpaid loans (76)
select
    status,
    count(*) as pocet_pujcek
from loan
group by status;
-- Status A and C represent repaid loans, B and D represents unpaid loans.

-- 3) Analysis of accounts - Write a query that ranks accounts according to the following criteria:
-- number of given loans (decreasing),
-- amount of given loans (decreasing),
-- average loan amount,
-- Only fully paid loans are considered.

select
    account_id,
    count(amount) as number_of_given_loans,
    sum(amount) as amount_of_given_loans,
    avg(amount) as average_loan_given
from loan
where status IN ('A', 'C')
group by account_id
order by
        number_of_given_loans desc,
        amount_of_given_loans desc;

-- 4) Fully paid loans. Find out the balance of repaid loans, divided by client gender.  Check the query.
-- I am not sure what balance means, so find number of loans, amount of loans and average loan amount devided by gender.
with paid_loans as (
    select
        c.gender,
        count(loan_id) as number_of_loans,
        sum(amount) as amount_of_loans,
        avg(amount) as average_amount_loans
    from loan l
    join account a on l.account_id = a.account_id
    join disp d on a.account_id = d.account_id
    join client c on d.client_id = c.client_id
    where status IN('A','C') AND d.type = 'OWNER'
    group by c.gender
)
-- using temporary table we can check if the number of repaid loans from previous task (606) is equal to sum of number of loans devided by gender.
select
    sum(number_of_loans)
from paid_loans;

-- Client analysis - part 1
-- 5)Modifying the queries from the exercise on repaid loans, answer the following questions:
-- a)Who has more repaid loans - women or men?
-- b)What is the average age of the borrower divided by gender?

select
    c.gender,
    count(loan_id) as number_of_loans,
    sum(amount) as amount_of_loans,
    avg(2024 - extract(year from c.birth_date)) as age
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where status IN('A','C') AND d.type = 'OWNER'
group by c.gender;

-- 5a) Women have more paid loans.
-- 5b) The average age of borrower is 66.8 years for men and 64.8 for women.

-- 6)Client analysis - part 2. Make analyses that answer the questions:      Select only owners of accounts as clients.
-- a) which area has the most clients,
-- b) in which area the highest number of loans was paid,
-- c) in which area the highest amount of loans was paid.

-- 6A)
select
    d.A2 as district,
    count(distinct c.client_id) as number_of_client
from client c
join district d on c.district_id = d.district_id
group by d.A2
order by number_of_client desc;
-- The most clients has Hl.m. Praha (663).

-- 6b)
select
    dist.A2 as district,
    count(loan_id) as number_of_repaid_loans
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
join district dist on a.district_id = dist.district_id
where l.status IN ('A','C') and d.type =  'OWNER'
group by dist.A2;
-- The highest number of loans was paid in Hl.m. Praha (77).

-- 6c)
select
    dist.A2 as district,
    sum(amount) as total_amount
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
join district dist on a.district_id = dist.district_id
where d.type = 'OWNER'
group by dist.A2
order by total_amount desc;
-- The highest amnout of loan was pain in HL.m Praha (12 932 412)

-- 7)Client analysis - part 3 Use the query created in the previous task and modify it to determine the percentage of each district in the total amount of loans granted.
-- (if i am to proceed from the previous example, it MUST BE loans REPAID)
with loans_by_district as (
    select
        dist.A2 as district,
        count(distinct c.client_id) as number_of_client,
        count(loan_id) as number_of_repaid_loans,
        sum(amount) as loans_given_amnout
    from loan l
    join account a on l.account_id = a.account_id
    join disp d on a.account_id = d.account_id
    join client c on d.client_id = c.client_id
    join district dist on a.district_id = dist.district_id
    where l.status IN ('A','C') and d.type =  'OWNER'
    group by dist.A2
)
select
    *,
    loans_given_amnout/ sum(loans_given_amnout) over () as share_amount
from loans_by_district
order by share_amount desc;

-- 8) Selection - part 1, Client selection. Check the database for the clients who meet the following results:  And we assume that the account balance is loan amount - payments.
-- their account balance is above 1000,
-- they have more than 5 loans,
-- they were born after 1990.

select
    c.client_id,
    count(loan_id) as number_of_loans,
    sum(amount - payments) as client_balance
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where d.type = 'OWNER' AND extract(year from birth_date) > 1990
group by c.client_id
having
    sum(amount - payments) > 1000
    and count(loan_id) >5;

-- The result is empty table.

-- 9)Selection - part 2)From the previous exercise you probably already know that there are no customers who meet the requirements. Make an analysis to determine which condition caused the empty results.
-- I will test each condition separately.
-- test birt date
select
    c.client_id,
    c.birth_date
from client c
where extract(year from birth_date) > 1990;
-- There are no clients bor after 1990 in the database.

-- test number of loan > 5
select
    c.client_id,
    count(loan_id) as number_of_loans
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where d.type = 'OWNER'
group by c.client_id
having count(loan_id) > 5;
-- There are no clients in the database wit more than 5 loans.

-- test celient balance > 1000
select
    c.client_id,
    sum(amount - payments) as client_balance
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where d.type = 'OWNER'
group by c.client_id
having sum(amount - payments) > 1000;

-- 10)Expiring cards Write a procedure to refresh the table you created (you can call it e.g. cards_at_expiration) containing the following columns:
-- client id,
-- card id,
-- expiration date - assume that the card can be active for 3 years after issue date,
-- client address (column A3 is enough).

-- připrava
with clients_and_expiration_date as (
    select
        c.client_id,
        card_id,
        date_add(issued, interval 3 year) as expiration_date,
        A3 as client_adress
    from card ca
    join disp d on ca.disp_id = d.disp_id
    join client c on d.client_id = c.client_id
    join district dist on c.district_id = dist.district_id
)
select *
from clients_and_expiration_date
where '2000-01-01' between date_add(expiration_date, interval -7 day) AND expiration_date;

-- create new table
create table financial8_127.cards_at_expiration
(
    client_id       int                      not null,
    card_id         int default 0            not null,
    expiration_date date                     null,
    A3              varchar(15) charset utf8 not null,
    generated_for_date date                     null
);

-- create procedure
DELIMITER //
create procedure update_cards_at_expiration_mm(p_date DATE)
begin
    insert into cards_at_expiration (client_id, card_id, expiration_date, A3, generated_for_date)

    select
        c.client_id,
        card_id,
        date_add(issued, interval 3 year) as expiration_date,
        A3 as client_adress,
        p_date
    from card ca
    join disp d on ca.disp_id = d.disp_id
    join client c on d.client_id = c.client_id
    join district dist on c.district_id = dist.district_id
    where p_date between DATE_SUB(DATE_ADD(ca.issued, INTERVAL 3 year),INTERVAL 7 DAY)
        AND date_add(ca.issued, interval 3 year);
END //
DELIMITER ;

-- check
call update_cards_at_expiration_mm('2000-01-01');
select *
from cards_at_expiration;

