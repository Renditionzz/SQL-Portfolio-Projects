/*
Cleaning Data
*/



-------------------------------------------------------------------------------------
-- Simplify Sales Date, Removing Time from Date
-------------------------------------------------------------------------------------

select *
from PortfolioProject..NashvilleHousing

--Test if converted sales date matches our needs
select SaleDate, convert(Date,SaleDate)
from PortfolioProject..NashvilleHousing

-- We then add a column to put our converted sales date to our table
alter table NashvilleHousing
add SalesDateConverted Date;

-- Next, we update our SalesDateConverted column to include the converted date
update NashvilleHousing
set SalesDateConverted = CONVERT(Date,SaleDate)

-- Finally, we check to confirm the new column has the converted date
select SalesDateConverted, convert(Date,SaleDate)
from PortfolioProject..NashvilleHousing
-------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------
--Populate Property Address Data
-------------------------------------------------------------------------------------

-- First, we look at the property addresses in the order of the parcel ID to see if the parcel ID equates to the same address
select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is null
order by ParcelID


-- Create a query that displays what values will be copied to the property address
select orig.ParcelID,orig.PropertyAddress, dup.ParcelID,dup.PropertyAddress, isnull(orig.PropertyAddress,dup.PropertyAddress) as AddressToBeCopied
from PortfolioProject..NashvilleHousing orig
join PortfolioProject..NashvilleHousing dup
on orig.ParcelID = dup.ParcelID
and orig.[UniqueID ] != dup.[UniqueID ]
where orig.PropertyAddress is null


--Update the table with the property address information
update orig
set PropertyAddress = isnull(orig.PropertyAddress,dup.PropertyAddress)
from PortfolioProject..NashvilleHousing orig
join PortfolioProject..NashvilleHousing dup
on orig.ParcelID = dup.ParcelID
and orig.[UniqueID ] != dup.[UniqueID ]
where orig.PropertyAddress is null

-- Finally, confirm the null addresses are removed by running the following query
select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is null
order by ParcelID




-------------------------------------------------------------------------------------
--Breaking Out Address into Individual Columns (Address, City, State)
-------------------------------------------------------------------------------------

-- First, we check the property addresses to see how the data is formatted
select PropertyAddress
from PortfolioProject..NashvilleHousing

-- Next, we separate the address from the city by finding the delimiter (comma) and create a substring off its position
select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as City
from PortfolioProject..NashvilleHousing


--We then add two new columns for where we can put our altered information
alter table NashvilleHousing
add PropertySplitAddress nvarchar(255)

update NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

alter table NashvilleHousing
add PropertySplitCity nvarchar(255)

update NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))


-- Finally, we confirm the new information is added in our table.

select *
from PortfolioProject..NashvilleHousing


-- Now that Property Addresses are complete, next is separating the owner addresses

select OwnerAddress
from PortfolioProject..NashvilleHousing


-- Separating addresses using parsename instead of substring for simplicity.
select
parsename(replace(OwnerAddress,',','.'),3), /* Address */
parsename(replace(OwnerAddress,',','.'),2), /* City */
parsename(replace(OwnerAddress,',','.'),1) /* State */
from PortfolioProject..NashvilleHousing


-- Then we add the appropriate columns and update them with the updated owner address information

alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255)

update NashvilleHousing
set OwnerSplitAddress = parsename(replace(OwnerAddress,',','.'),3) /* Address */

alter table NashvilleHousing
add OwnerSplitCity nvarchar(255)

update NashvilleHousing
set OwnerSplitCity = parsename(replace(OwnerAddress,',','.'),2) /* City */

alter table NashvilleHousing
add OwnerSplitState nvarchar(255)

update NashvilleHousing
set OwnerSplitState = parsename(replace(OwnerAddress,',','.'),1) /* State */


-- we finally doublecheck to confirm that the information is properly input.
select *
from PortfolioProject..NashvilleHousing

-------------------------------------------------------------------------------------
-- Change Y/N to Yes and No in "Sold as Vacant" field
-------------------------------------------------------------------------------------

-- First, we check to see all of the values in the SoldAsVacant column and decide which is the popular use case, which is "Yes" and "No"
select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2

-- Next, we create a case query that will convert the 'Y' and 'N' to appropriate values
select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
     when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end
from PortfolioProject..NashvilleHousing

-- Finally, we then update the table with our correct values
update NashvilleHousing
set SoldAsVacant =
case when SoldAsVacant = 'Y' then 'Yes'
     when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end





-------------------------------------------------------------------------------------
-- Remove Duplicates
-------------------------------------------------------------------------------------
-- Note: removing duplicates in SQL is not standard practice, but important to know

-- First, we create a CTE to add a temporary column that lists the amount of times a row has been duplicated
with RowNumCTE as (
select *,
	ROW_NUMBER() over (
	partition by ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	order by
		UniqueID
		) row_num
from PortfolioProject..NashvilleHousing
)
-- Next, we then delete any of those rows where the number is over 1, meaning it is a duplicate row
delete
from RowNumCTE
where row_num > 1







-------------------------------------------------------------------------------------
-- Delete Unused Columns
-------------------------------------------------------------------------------------
-- Note: This is not best practice to do, but still important to know
select *
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
drop column SaleDate