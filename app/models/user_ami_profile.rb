class UserAmiProfile < ApplicationRecord
  belongs_to :user

  encrypts :fc_hash

  def self.show_checkbox_in_user_form?(user, unconfirmed_rdv)
    return false unless Ami.enabled?

    unconfirmed_rdv&.organisation&.ami_enabled?
    profile_in_ami_organisation = unconfirmed_rdv.blank? && user.organisations.where(ami_enabled: true).any?
    hash = UserAmiProfile.find_by(user: user)

    hash && (rdv_for_organisation_with_ami || profile_in_ami_organisation)
  end

  def self.update_notify_by_ami(user, boolean, synchronous: false)
    return if boolean.nil? # Si le champs n'apparait pas dans le formulaire, on ne veut pas changer de valeur
    return unless Ami.enabled?

    ami_profile = user.user_ami_profile

    return unless ami_profile

    if synchronous
      Ami::UpdateConsentJob.new.perform(ami_profile.fc_hash, boolean)
    else
      Ami::UpdateConsentJob.perform_later(ami_profile.fc_hash, boolean)
    end

    ami_profile&.update(notify_by_ami: boolean)
  end
end
