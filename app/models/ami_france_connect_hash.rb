class AmiFranceConnectHash < ApplicationRecord
  belongs_to :user

  encrypts :fc_hash
end
