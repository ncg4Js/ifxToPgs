package compatPostGres

define dictRowId dictionary of base.SqlHandle

PUBLIC FUNCTION last_rowid(p_table STRING) RETURNS BIGINT
    DEFINE ifx_reg BIGINT
    DEFINE drv     STRING

    -- FIRST, before anything else: on Informix the answer is already in
    -- the register and the next SQL statement destroys it.
    LET ifx_reg = sqlca.sqlerrd[6]

    LET drv = fgl_db_driver_type()

    CASE
        WHEN drv == "ifx"  RETURN ifx_reg
        WHEN drv == "pgs"  
            RETURN pgs_last_rowid(p_table)
        OTHERWISE
            CALL errorlog(SFMT("last_rowid: no support for driver '%1'", drv))
            RETURN NULL
    END CASE
END FUNCTION


public function pgs_last_rowid(p_table string) returns bigint
    define h base.SqlHandle
    define lastRowId bigint = -1

    if dictRowId.contains(p_table) then
        let h = dictRowId[p_table]
    else
        let h = base.SqlHandle.create()
        call h.prepare(sfmt("SELECT currval(pg_get_serial_sequence('%1', 'rowid'))", p_table));
        let dictRowId[p_table] = h
    end if 

    call h.open()
    call h.fetch()
    if sqlca.sqlcode == 0 then
        let lastRowId = h.getResultValue(1)
    end if 
    return lastRowId
end function 