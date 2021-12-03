# frozen_string_literal: true

class Team < ApplicationRecord
  belongs_to :territory

  has_many :agent_teams, dependent: :destroy
  has_many :agents, through: :agent_teams
end
