import util 
import fgl compatPostGres.last_rowid

schema fruits

function main()
   database fruits

   call util.Math.srand()

   display ""
   display sfmt("Executing at %1", current hour to second)

   # try to insert
   try 
      INSERT INTO fruits (entryid, fruit_name, variety, color, season) 
         VALUES (1000, 'Abrunho', 'Naosei', 'Red', 'Verao');
   catch
      display "Could not insert: ", sqlerrmessage
      display util.json.stringify(sqlca)
   end try

   # retrieve last "rowid"
   display last_rowid("fruits")

   # update
   var _c smallint = util.Math.rand(25)
   try
      UPDATE fruits SET rating = _c WHERE entryId = 1000;
      display sfmt("Abrunho updated to %1", _c)
   catch
      display sfmt("Could not update rating to %1: %2 ", _c, sqlerrmessage)
      display util.json.stringify(sqlca)
   end try

   
end function 