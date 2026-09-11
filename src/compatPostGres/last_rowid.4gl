package compatPostGres


PUBLIC FUNCTION last_rowid(p_table STRING) RETURNS BIGINT
    DEFINE ifx_reg BIGINT
    DEFINE drv     STRING

    -- FIRST, before anything else: on Informix the answer is already in
    -- the register and the next SQL statement destroys it.
    LET ifx_reg = sqlca.sqlerrd[6]

    LET drv = fgl_db_driver_type()

    CASE
        WHEN drv == "ifx"  RETURN ifx_reg
        WHEN drv == "pgs"  RETURN pgs_last_rowid(p_table)
        OTHERWISE
            CALL errorlog(SFMT("last_rowid: no support for driver '%1'", drv))
            RETURN NULL
    END CASE
END FUNCTION
