
#psql "host=PostGreSQL dbname=northwind user=pguser password=pgpass port=5432" \
psql \
  -h postgres \
  -p 5432 \
  -d postgres \
  -U pguser \
  -W \
  -f northwind.postgre.sql \
  -v ON_ERROR_STOP=1 \
  -1 \
  -L ./psql_run.log
