#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=periodic_table --tuples-only -c"

# BUILD: Build modified SQL from existing SQL
BUILD() {
  # You should rename the weight column to atomic_mass
  # You should rename the melting_point column to melting_point_celsius and the boiling_point column to boiling_point_celsius
  # Your melting_point_celsius and boiling_point_celsius columns should not accept null values
  # You should add the UNIQUE constraint to the symbol and name columns from the elements table
  # Your symbol and name columns should have the NOT NULL constraint
  S1=$($PSQL  "ALTER TABLE properties RENAME COLUMN weight TO atomic_mass;
              ALTER TABLE properties RENAME COLUMN melting_point TO melting_point_celsius;
              ALTER TABLE properties RENAME COLUMN boiling_point TO boiling_point_celsius;
              ALTER TABLE properties ALTER COLUMN melting_point_celsius SET NOT NULL;
              ALTER TABLE properties ALTER COLUMN boiling_point_celsius SET NOT NULL;
              ALTER TABLE elements ADD UNIQUE(symbol);
              ALTER TABLE elements ADD UNIQUE(name);
              ALTER TABLE elements ALTER COLUMN symbol SET NOT NULL;
              ALTER TABLE elements ALTER COLUMN NAME SET NOT NULL")
  echo ">> $S1"

  # You should set the atomic_number column from the properties table as a foreign key that references the column of the same name in the elements table
  # You should create a types table that will store the three types of elements
  # Your types table should have a type_id column that is an integer and the primary key
  # Your types table should have a type column that's a VARCHAR and cannot be null. It will store the different types from the type column in the properties table
  # You should add three rows to your types table whose values are the three different types from the properties table
  S2=$($PSQL "ALTER TABLE properties ADD FOREIGN KEY(atomic_number) REFERENCES elements(atomic_number);
              CREATE TABLE types(type_id INT PRIMARY KEY, type VARCHAR(50) NOT NULL);
              INSERT INTO types(type_id,type) VALUES(1,'metal'),(2,'nonmetal'),(3,'metalloid')")
  echo ">> $S2"

  # Your properties table should have a type_id foreign key column that references the type_id column from the types table. It should be an INT with the NOT NULL constraint
  # Each row in your properties table should have a type_id value that links to the correct type from the types table
  S3=$($PSQL  "ALTER TABLE properties ADD COLUMN type_id INT;
              ALTER TABLE properties ADD FOREIGN KEY(type_id) REFERENCES types(type_id);
              UPDATE properties SET type_id=1 WHERE type='metal';
              UPDATE properties SET type_id=2 WHERE type='nonmetal';
              UPDATE properties SET type_id=3 WHERE type='metalloid';
              ALTER TABLE properties ALTER COLUMN type_id SET NOT NULL")
  echo ">> $S3"

  # You should capitalize the first letter of all the symbol values in the elements table. Be careful to only capitalize the letter and not change any others
  S4=$($PSQL  "UPDATE elements SET symbol=INITCAP(symbol)")
  echo ">> $S4"

  # You should remove all the trailing zeros after the decimals from each row of the atomic_mass column. You may need to adjust a data type to DECIMAL for this. The final values they should be are in the atomic_mass.txt file
  S5=$($PSQL  "ALTER TABLE properties ALTER COLUMN atomic_mass TYPE FLOAT")
  echo ">> $S5"

  # You should add the element with atomic number 9 to your database. Its name is Fluorine, symbol is F, mass is 18.998, melting point is -220, boiling point is -188.1, and it's a nonmetal
  # You should add the element with atomic number 10 to your database. Its name is Neon, symbol is Ne, mass is 20.18, melting point is -248.6, boiling point is -246.1, and it's a nonmetal
  S6=$($PSQL  "INSERT INTO elements(atomic_number,symbol,name) 
              VALUES(9,'F','Fluorine'),
              (10,'Ne','Neon');
              INSERT INTO properties(atomic_number,type_id,atomic_mass,melting_point_celsius,boiling_point_celsius)
              VALUES(9,2,18.998,-220,-188.1),
              (10,2,20.18,-248.6,-246.1)")
  echo ">> $S6"
}

# MAIN PROGRAM
NUMBER_RE='^[0-9]+$'
SYMBOL_RE='^[A-Z][a-z]?$'

QUERY() {
  QUERY_RESULT=$($PSQL "SELECT atomic_number,name,symbol,type,atomic_mass,melting_point_celsius,boiling_point_celsius 
                        FROM properties INNER JOIN elements USING (atomic_number) 
                        FULL JOIN types USING(type_id) 
                        WHERE $1")

  if [[ -z $QUERY_RESULT ]]                      
  then
    echo "I could not find that element in the database."
  else
    echo "$QUERY_RESULT" | while read AT_NUM BAR NAME BAR SYMBOL BAR TYPE BAR MASS BAR MELTING BAR BOILING
    do
      # Print query result
      echo "The element with atomic number $AT_NUM is $NAME ($SYMBOL). It's a $TYPE, with a mass of $MASS amu. $NAME has a melting point of $MELTING celsius and a boiling point of $BOILING celsius."
    done
  fi
}

MAIN() {
  if [[ -z $1 ]]
  then
    echo "Please provide an element as an argument."
  else
    # if argument is an atomic number
    if [[ $1 =~ $NUMBER_RE ]]
    then
      CONDITION="atomic_number=$1"
    # if argument is a symbol
    elif [[ $1 =~ $SYMBOL_RE ]]
    then
      CONDITION="symbol='$1'"
    # if argument is a name
    else
      CONDITION="name='$1'"
    fi

    QUERY $CONDITION
  fi
}

MAIN $1