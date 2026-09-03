class UserAmiProfile < ApplicationRecord
  belongs_to :user

  encrypts :fc_hash

  def self.update_notify_by_ami(user, boolean)
    return unless Ami.enabled?

    ami_profile = UserAmiProfile.find_by(user: user)
    Ami::UpdateConsentJob.perform_later(ami_profile.fc_hash, boolean)

    ami_profile&.update(notify_by_ami: boolean)
  end
end
