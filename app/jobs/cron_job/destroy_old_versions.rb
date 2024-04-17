class CronJob::DestroyOldVersions < CronJob
  def perform
    # Versions are used in RDV exports, and RDVs are currently kept for 2 years.
    PaperTrail::Version.where("created_at < ?", 2.years.ago).delete_all
  end

  private

  def model_names_with_no_personal_information
    %w[
      WebhookEndpoint
      Service
      Lieu
      Organisation
      Territory
      Team
      MotifCategory
      Motif
      Plage_ouverture
      Territory_service
    ]
  end
end
