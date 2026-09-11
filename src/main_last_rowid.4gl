import fgl compatPostGres.last_rowid

schema fruits

function main()
   database fruits
   sql
      INSERT INTO fruits (fruit_name, variety, color, season) 
         VALUES ('Abrunho', 'Naosei', 'Red', 'Verao');
   end sql

   display last_rowid("fruits")
end function 