class CaldavConfig < ApplicationRecord
  encrypts :caldav_password, deterministic: true

  belongs_to :agent
end
