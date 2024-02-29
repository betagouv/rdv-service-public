DO $$ 
DECLARE 
    stmt text; 
BEGIN 
    -- Drop constraints
    FOR stmt IN 
        SELECT 'ALTER TABLE "' || table_name || '" DROP CONSTRAINT IF EXISTS "' || constraint_name || '" CASCADE;' 
        FROM information_schema.table_constraints 
        WHERE table_schema = 'public' 
    LOOP 
        EXECUTE stmt; 
    END LOOP;

    -- Drop tables
    FOR stmt IN 
        SELECT 'DROP TABLE IF EXISTS "' || tablename || '" CASCADE;' 
        FROM pg_tables 
        WHERE schemaname = 'public' 
    LOOP 
        EXECUTE stmt; 
    END LOOP;

    -- Drop indexes
    FOR stmt IN 
        SELECT 'DROP INDEX IF EXISTS "' || indexname || '" CASCADE;' 
        FROM pg_indexes 
        WHERE schemaname = 'public' 
    LOOP 
        EXECUTE stmt; 
    END LOOP;
END $$;
