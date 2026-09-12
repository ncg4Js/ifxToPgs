
#psql "host=PostGreSQL dbname=northwind user=pguser password=pgpass port=5432" \
psql \
  -h postgres \
  -p 5432 \
  -d fruits \
  -U pguser \
  -W \
  -f sql/generate_db_pgs.sql \
  -v ON_ERROR_STOP=1 \
  -1 \
  -L ./psql_run.log
