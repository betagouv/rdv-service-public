# frozen_string_literal: true

class UserNote < ApplicationRecord
  belongs_to :user
  belongs_to :organisation
  belongs_to :agent

  validates :text, presence: true
end
