# frozen_string_literal: true

module Agent::SoftDeletable
  extend ActiveSupport::Concern

  def soft_delete
    raise SoftDeleteError, "agent still has attached resources" if organisations.any? || plage_ouvertures.any? || absences.any?

    # skip Devise email notifications that are normally triggered when updating email
    skip_reconfirmation!

    Agent.transaction do
      sector_attributions.destroy_all
      update!(deleted_at: Time.zone.now, email_original: email, email: deleted_email, uid: deleted_email)
    end
  end

  private

  def deleted_email
    "agent_#{id}@deleted.rdv-solidarites.fr"
  end
end
