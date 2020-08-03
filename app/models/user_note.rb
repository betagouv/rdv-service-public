class UserNote < ActiveRecord::Base
  belongs_to :user
  belongs_to :organisation
  belongs_to :agent
end
