-- Data Cleaning --
-- https://www.kaggle.com/datasets/swaptr/layoffs-2022 --

select * from layoffs;

-- 1. Rimuovere duplicati-- 
-- 2. Standardizzazione dei dati--
-- 3. Spazi/Valori nulli--
-- 4. Rimuovere colonne non necessarie--

-- 1. RIMOZIONE DUPLICATI--

-- 1. Creazione di una tabella uguale su cui operare--
create table layoffs_staging like layoffs;

insert layoffs_staging
select * from layoffs;

-- 2. Partion by per verificare il numero di duplicati presenti, siccome non è presente la colonna unica ID--
SELECT *,
ROW_NUMBER() OVER (
		PARTITION BY company, location, industry, total_laid_off,percentage_laid_off, `date`, stage, country,
        funds_raised_millions) AS row_num
	FROM layoffs_staging;
 
-- 3. Creazione CTE in cui riscontriamo presenza duplicati--
with duplicate_cte as
(
	SELECT *,
ROW_NUMBER() OVER (
		PARTITION BY company, location, industry, total_laid_off,percentage_laid_off, `date`, stage, country,
        funds_raised_millions) AS row_num
	FROM layoffs_staging
)
select * from duplicate_cte
where row_num >1;

-- 4. Non avendo la colonna Id dobbiamo creare un'altra tabella uguale per eliminare i duplicati e aggiungiamo una nuova colonna 'row_num'--

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
	`row_num`int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from layoffs_staging2;

-- 5. Inseriamo gli stessi dati--
insert into layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
		PARTITION BY company, location, industry, total_laid_off,percentage_laid_off, `date`, stage, country,
        funds_raised_millions) AS row_num
	FROM layoffs_staging;
    
-- 6. Rimozione dei duplicati--
Delete 
from layoffs_staging2
where row_num >1;

Select * 
from layoffs_staging2;

-- 2. STANDARDIZZAZIONE DEI DATI-- 
-- 1. Eliminazione spazi con TRIM--

Select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company= trim(company);

-- 2. Modifica dei dati ridondanti--
update layoffs_staging2
set industry = "Crypto"
where industry like "Crypto%";

-- 3. Modifica di un campo con irregolarità--
update layoffs_staging2
set country = Trim(Trailing "." from country)
where country like "United States%";

select distinct country from layoffs_staging2
order by 1;

-- 4. Modifica tipo di dato della colonna date, da text a date--
select `date`,
str_to_date(`date`, "%m/%d/%Y")
from layoffs_staging2;

update layoffs_staging2
set `date`=str_to_date(`date`, "%m/%d/%Y");

Alter table layoffs_staging2
modify column  `date` date;

-- 3. RIMUOVERE SPAZI/VALORI NULLI--	

-- 1.Check sulle colonne che presentanto valori nulli e spazi vuoti--

Select * from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null;

-- 2. Modifica dei campi vuoti in null--
update layoffs_staging2
set industry = null
where industry= '';

-- 3. Self join + update sulla stesa tabella
Select t1.industry, t2.industry 
from layoffs_staging2 t1
join layoffs_staging2 t2 
on t1.company=t2.company
and t1.location=t2.location
where t1.industry is null and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2 
	on t1.company=t2.company
set t1.industry=t2.industry
where t1.industry is null and
 t2.industry is not null;

select * from layoffs_staging2
where company ="Airbnb";

-- 4. Alcune colonne presentano ancora valori nulli per mancanza di dati dal dataset per cui non è possibile cambiarli--

-- 4. RIMUOVERE COLONNE NON NECESSARIE--

-- 1. Selezioniamo le colonne che non sono necessarie--
	select * from layoffs_staging2
    where total_laid_off is null 
    and percentage_laid_off is null;
-- 2. Le eliminiamo--
    delete 
    from layoffs_staging2
	where total_laid_off is null 
    and percentage_laid_off is null;
    
    select * from layoffs_staging2;
 -- 3. Eliminamo la colonna row_num che non ci serve più--  
    alter table layoffs_staging2
    drop column row_num;