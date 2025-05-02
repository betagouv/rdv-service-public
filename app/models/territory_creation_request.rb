class TerritoryCreationRequest < ApplicationRecord
  has_paper_trail

  belongs_to :agent

  validates :organisation_name, :territory_name, :service_name, presence: true
  validates :agent_id, uniqueness: true

  def possible_duplicate_organisations_by_email_domain
    email_domain = agent.email.split("@").last
    Organisation.joins(:agents).where("agents.email ilike ?", "%@#{email_domain}").distinct
  end

  def possible_duplicate_organisations_by_siret
    return Organisation.none if agent.proconnect_siret.blank?

    Organisation.joins(:agents).where(agents: { proconnect_siret: agent.proconnect_siret }).distinct
  end

  validate :can_only_have_one_response

  private

  def can_only_have_one_response
    if response_changed? && !response_was.nil?
      errors.add(:response, "Un autre admin a déjà traité cette demande")
    end
  end
end
