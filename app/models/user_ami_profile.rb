class UserAmiProfile < ApplicationRecord
  belongs_to :user

  encrypts :fc_hash

  def self.update_notify_by_ami(user, boolean)
    return unless Ami.enabled?

    ami_profile = UserAmiProfile.find_by(user: user)

    ami_profile&.update(notify_by_ami: boolean)
  end
end
