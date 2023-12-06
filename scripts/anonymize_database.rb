# commencer par charger en local un dump de production
Anonymizer.anonymize_all_data!

# en local, faire un pg_dump -d lapin_development --file=tmp/anonymized_dump.sql
# puis compresser le dump
# puis scalingo --app=rdv-service-public-etl --region=osc-secnum-fr1 run --file=tmp/anonymized_dump.sql.zip "bash"
