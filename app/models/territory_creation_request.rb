class TerritoryCreationRequest < ApplicationRecord
  has_paper_trail

  belongs_to :agent

  validates :organisation_name, :territory_name, :service_name, presence: true
  validates :agent_id, uniqueness: true

  def possible_duplicate_organisations_by_email_domain
    email_domain = agent.email.split("@").last
    Organisation.joins(:agents).where("agents.email ilike ?", "%@#{email_domain}").distinct
  end
end
