# Ces serializers sont utilisés par ActiveSupport pour automatiquement
# transmettre aux jobs les attributs des absences et plages d'ouverture.

Rails.application.config.active_job.custom_serializers << TodSerializer
Rails.application.config.active_job.custom_serializers << RecurrenceSerializer
