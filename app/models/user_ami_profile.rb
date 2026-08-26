class UserAmiProfile < ApplicationRecord
  belongs_to :user

  encrypts :fc_hash

  def self.update_notify_by_ami(user, boolean)
    return unless Ami.enabled?

    hash = UserAmiProfile.find_by(user: user)

    hash&.update(notify_by_ami: boolean)
  end
end
