class CronJob::DestroyOldVersions < CronJob
  def perform
    delete_old_versions_with_personal_information

    remove_personal_information_from_old_versions

    PaperTrail::Version.where("created_at < ?", 5.years.ago).delete_all
  end

  private

  def delete_old_versions_with_personal_information
    PaperTrail::Version.where.not(item_type: model_names_with_no_personal_information)
      .where("created_at < ?", 1.year.ago).delete_all
  end

  def remove_personal_information_from_old_versions
    PaperTrail::Version.where("created_at < ?", 1.year.ago)
      .where.not(whodunnit: nil).update_all(whodunnit: nil) # rubocop:disable Rails/SkipsModelValidations
  end

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
