import fgl compatPostGres.last_rowid

schema fruits

function main()
   database fruits
   try 
      INSERT INTO fruits (fruit_name, variety, color, season) 
         VALUES ('Abrunho', 'Naosei', 'Red', 'Verao');
   catch
      display "Could not insert"
   end try

   display last_rowid("fruits")
end function 