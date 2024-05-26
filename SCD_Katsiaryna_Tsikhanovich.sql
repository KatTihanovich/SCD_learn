ALTER TABLE DimEmployee
DROP CONSTRAINT DimEmployee_pkey CASCADE;

ALTER TABLE DimEmployee
ADD COLUMN StartDate TIMESTAMP,
ADD COLUMN EndDate TIMESTAMP,
ADD COLUMN isCurrent BOOLEAN DEFAULT TRUE,
ADD COLUMN ReportID SERIAL PRIMARY KEY;

UPDATE  DimEmployee
SET ReportID = DEFAULT;

UPDATE DimEmployee
SET StartDate = HireDate,
    EndDate = '9999-12-31';
   
CREATE OR REPLACE FUNCTION employees_update_function()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.Title <> NEW.Title OR OLD.Address <> NEW.Address) AND OLD.isCurrent AND NEW.isCurrent THEN
        UPDATE DimEmployee
        SET EndDate = current_timestamp,
            isCurrent = FALSE,
			Title = OLD.Title,
			Address = OLD.Address
        WHERE EmployeeID = OLD.EmployeeID AND isCurrent = TRUE;

      
        INSERT INTO DimEmployee (EmployeeID, LastName, FirstName, Title, BirthDate, HireDate, Address, City, Region, PostalCode, Country, HomePhone, Extension, StartDate, EndDate, isCurrent)
        VALUES (OLD.EmployeeID, OLD.LastName, OLD.FirstName, NEW.Title, OLD.BirthDate, OLD.HireDate, NEW.Address, OLD.City, OLD.Region, OLD.PostalCode, OLD.Country, OLD.HomePhone, OLD.Extension, current_timestamp, '9999-12-31', TRUE);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS employees_update_trigger ON DimEmployee CASCADE;
CREATE TRIGGER employees_update_trigger
AFTER UPDATE ON DimEmployee
FOR EACH ROW
EXECUTE FUNCTION employees_update_function();

--Check
UPDATE DimEmployee
SET city = 'Paris'
WHERE FirstName = 'Sara' and LastName = 'Davis' AND isCurrent = True;

DELETE FROM DimEmployee
WHERE FirstName = 'Russell' and LastName = 'King' AND isCurrent = True;
