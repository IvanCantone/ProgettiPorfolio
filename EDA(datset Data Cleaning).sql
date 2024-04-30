-- EDA del datset layoffs. Ulilizzo lo stesso dataset su cui ho fatto Data Cleaning.--
-- Varie query per esplorare il dataset-- 
select * from layoffs_staging2;

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

select * from layoffs_staging2
where percentage_laid_off= 1
order by funds_raised_millions desc;

select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

select industry, max(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

select company, sum(percentage_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

select stage, sum(percentage_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

select year(`date`), sum(percentage_laid_off)
from layoffs_staging2
group by year(`date`)
order by 2 desc;

select substring(`date`,1,7) as month_date, sum(total_laid_off)
from layoffs_staging2
where substring(`date`,1,7)  is not null
group by month_date
order by 1;

/* Questa query sostanzialmente restituisce tre colonne
month_date: ovvero mese e anno dei dati
total_off: totale dei licenziamenti
rolling_toatl: totale cumulativo dei licenziamenti fino a quel mese(SUM() over())
Con la CTE estraiamo i dati dalla tabella e calcoliamo il totale dei licenziamenti mensili, con SUBSTRING 
estraiamo nel caso specifico anno e mese dalla colonna 'date' e in fine raggruppiamo per mese*/
 
with Rolling_total as
(
select substring(`date`,1,7) as month_date, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`,1,7)  is not null
group by month_date
order by 1
)
select month_date, total_off, Sum(total_off) over(order by month_date) as rolling_total
from Rolling_total;

select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;
/*Questa query restituisce le prime cinque aziende con il numero più alto 
di licenziamenti per ciascun anno.
La prima CTE estrae i dati dalla tabella e li raggruppa per azienda e anno, utilizzando la funzione year()
e fa anche una somma dei licenziamenti totali sum().
La seconda CTE utilizza la prima e aggiunge una funzione, cioè dense_rank() ovvero una classifica basata sul
numero di licenziamenti per ogni anno e con l'aggiunta del partion by years, questa classifica viene effettuata
per ogni anno.
Infine l'ultima parte della query utilizza la seconda CTE e filtra la classifica restituendo solo le 
prime 5 aziende per numero di licenziamnti più alto per ogni anno
*/
with Company_year (company, years, total_laids_off) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), Company_year_rank as
(select *, dense_rank() over(partition by years order by total_laids_off desc) as Ranking
from Company_year
where years is not null
)
select * 
from Company_year_rank
where Ranking <= 5;