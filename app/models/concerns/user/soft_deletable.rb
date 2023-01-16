# frozen_string_literal: true

module User::SoftDeletable
  extend ActiveSupport::Concern

  def soft_delete(organisation = nil)
    self_and_relatives.each { _1.do_soft_delete(organisation) }
  end

  def can_be_soft_deleted_from_organisation?(organisation)
    Rdv.not_cancelled
      .future
      .joins(:users).where(users: self_and_relatives)
      .where(organisation: organisation)
      .empty?
  end

  protected

  def do_soft_delete(organisation)
    # skip Devise email notifications that are normally triggered when updating email
    skip_reconfirmation!

    if organisation.present?
      organisations.delete(organisation)
    else
      self.organisations = []
    end
    return save! if organisations.any? # only actually mark deleted when no orgas left

    update!(deleted_at: Time.zone.now, email_original: email, email: deleted_email)
  end

  def deleted_email
    "user_#{id}@deleted.rdv-solidarites.fr"
  end
end
