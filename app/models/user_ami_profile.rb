class UserAmiProfile < ApplicationRecord
  belongs_to :user

  encrypts :fc_hash

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
