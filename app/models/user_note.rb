class UserNote < ActiveRecord::Base
  belongs_to :user
  belongs_to :organisation
  belongs_to :agent

  validates_presence_of :text
end
