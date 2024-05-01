-- Data Cleaning --
-- https://www.kaggle.com/datasets/tmthyjames/nashville-housing-data--

-- 1. Standardizzazione dei dati--

select * from nashville;
-- Creazione di una tabella uguale per operare
create table nashville1 like nashville;

insert nashville1
select * from nashville;

-- Conversione formato data con funzione date--
update nashville1
set SaleDate_Converted= date(SalesDate_Converted);

select * from nashville1;


/* 2. Con queste query andiamo ad eseguire una selfjoin sulla tabella nashville1 selezionado due campi da ogni
tabella(Parcelid e PropertyAddress) e con l'aggiunta della funzione ifnull in sostanza ci restituisce a.PropertyAddress, se
viene riscontrato un valore NON vuoto(o null a seconda dei casi), altrimenti ci restituisce l'indirizzo presente in
b.PropertyAddress. 
In sostanza la query trova le righe all'interno della prima istanza(a.PropertyAddress) dove 
i campi sono vuoti e in questo caso restituisce gli indirizzi della seconda istanza(b.PropertyAddress)*/
select *
from nashville1;

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull(a.PropertyAddress,b.PropertyAddress)
from nashville1 as a
join nashville1 as b
on a.ParcelID=b.ParcelID
and a.UniqueID <> b.UniqueID
where a.PropertyAddress = " ";

update nashville1 as a
join nashville1 as b
	on a.ParcelID=b.ParcelID
	and a.UniqueID <> b.UniqueID
set a.PropertyAddress = ifnull(a.PropertyAddress,b.PropertyAddress)
where a.PropertyAddress = '' AND b.PropertyAddress != '';

/*3. Con la seguente query in sostanza andiamo a separare l'indirzzo dalla città presenti nella colonna
PropertyAddress e utilizziamo in pratica la virgola come punto di divisione.
Con la prima substring estraiamo una sottoastringa fino ad arrivare alla virgola(-1 perchè non 
vogliamo la virgola) e quindi ricaviamo l'indirizzo, mentre con la seconda substring ricaviamo una sottostringa
partendo dalla posizione successiva alla virgola(+1) e quindi ricaviamo la città */
select *
from nashville1;

select PropertyAddress,
substring(PropertyAddress,1, locate(',', PropertyAddress) -1) as Address,
substring(PropertyAddress,locate(',', PropertyAddress) +1, length(PropertyAddress)) as Address
from nashville1;

-- Aggiunte nuove colonne con i dati ricavati, ovvero l'indirizzo e la città in due colonne diverse--
alter table nashville1
add Column Property_split_address varchar(255) after PropertyAddress;

update nashville1
set Property_split_address=substring(PropertyAddress,1, locate(',', PropertyAddress) -1) ;

alter table nashville1
add Column Property_city varchar(255) after Property_split_address ;

update nashville1
set Property_city=substring(PropertyAddress,locate(',', PropertyAddress) +1, length(PropertyAddress)) ;


/* Altro metodo in questo caso la colonna OwnerAddress presenta tre informazioni, ovvero indirizzo, città e
stato e con la funzione substring_index andiamo a separare le tre informazioni utilizzando la virgola come 
punto di divisione
*/
select OwnerAddress
from nashville1;

select substring_index(OwnerAddress, ',', 1) AS Address,
substring_index(substring_index(OwnerAddress, ',', 2), ',', -1) AS City,
substring_index(OwnerAddress, ',', -1) AS State
from nashville1;

-- Aggiunte e popolate le tre colonne(Owner_split_address,Owner_city,Owner_state)
alter table nashville1
add Column Owner_split_address varchar(255) after OwnerAddress;

update nashville1
set Owner_split_address= substring_index(OwnerAddress, ',', 1);

alter table nashville1
add Column Owner_city varchar(255) after Owner_split_address ;

update nashville1
set Owner_city=substring_index(substring_index(OwnerAddress, ',', 2), ',', -1);

alter table nashville1
add Column Owner_state varchar(255) after Owner_city ;

update nashville1
set Owner_state=substring_index(OwnerAddress, ',', -1);

/*4. Con questa query andiamo ad utilizzare il CASE per cambiare, nello specifico, le Y in YES e le N in NO all'interno
della colonna SoldAsVacant*/

select SoldAsVacant,
	case
		when SoldAsVacant= "Y" then "Yes"
        when SoldAsVacant= "N" then "No"
        else SoldAsVacant
    end as Sold
from nashville1;

update nashville1
set SoldAsVacant=case
		when SoldAsVacant= "Y" then "Yes"
        when SoldAsVacant= "N" then "No"
        else SoldAsVacant
    end ;
 
 select SoldAsVacant, count(SoldAsVacant) as Sold
 from nashville1
 group by SoldAsVacant;
 
 /*5. Rimozione duplicati con CTE*/

with Row_cte as(
select *,
	row_number() over(
    partition by ParcelID,
				PropertyAddress,
                SalePrice,
                SaleDate_Converted,
                LegalReference
				order by UniqueID
				) as row_num
from nashville1
)
delete
from Row_cte
Where row_num >1;

 /*5. Rimozione duplicati con Subquery(In Mysql non possiamo eliminare righe direttamente da una CTE,poichè
 non è una tabella fisica*/
delete from nashville1
where UniqueID in (
	select UniqueID
	from( 
		select UniqueID,
		row_number() over(
		partition by ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate_Converted,
					LegalReference
					order by UniqueID
					) as row_num
	from nashville1
		) as Row_cte
where row_num >1
);


-- 6. Rimozione colonne inutili--
select * from nashville1;

alter table nashville1
drop column TaxDistrict;
    
    