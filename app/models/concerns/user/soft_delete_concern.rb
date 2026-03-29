module User::SoftDeleteConcern
  extend ActiveSupport::Concern

  def soft_delete!(organisation = nil)
    if (organisation.present? && !can_be_soft_deleted_from_organisation?(organisation)) ||
       (organisation.nil? && !can_be_soft_deleted?)
      raise StandardError, "L’usager ou un de ses proches a au moins un RDV à venir"
    end

    self_and_relatives.each { _1.do_soft_delete(organisation) }
  end

  def soft_deleted?
    deleted_at.present?
  end

  def can_be_soft_deleted?
    upcoming_rdvs_for_self_or_relatives.empty?
  end

  def can_be_soft_deleted_from_organisation?(organisation)
    upcoming_rdvs_for_self_or_relatives
      .where(organisation: organisation)
      .empty?
  end

  def do_soft_delete(organisation)
    if organisation.present?
      organisations.delete(organisation)
    else
      self.organisations = []
    end
    return save! if organisations.any? # only actually mark deleted when no orgas left

    Anonymizer.anonymize_record!(self)
    receipts.each { |r| Anonymizer.anonymize_record!(r) }
    rdvs
      .select { |r| r.users.where(deleted_at: nil).where.not(id:).empty? }
      .each { |r| Anonymizer.anonymize_record!(r) }
    annotations.destroy_all
    versions.destroy_all
    update_columns( # rubocop:disable Rails/SkipsModelValidations
      first_name: "Usager supprimé",
      last_name: "Usager supprimé",
      deleted_at: Time.zone.now,
      email: deleted_email
    )
    reload # anonymizer operates outside the realm of rails knowledge
  end
end
