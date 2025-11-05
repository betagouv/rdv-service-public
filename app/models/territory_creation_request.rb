class TerritoryCreationRequest < ApplicationRecord
  has_paper_trail

  belongs_to :agent

  validates :organisation_name, presence: true
  validates :agent_id, uniqueness: true
  validate :can_only_have_one_response

  delegate :possible_duplicate_organisations_by_email_domain, :possible_duplicate_organisations_by_siret, to: :agent

  private

  def can_only_have_one_response
    if response_changed? && !response_was.nil?
      errors.add(:response, "Un autre super admin a déjà traité cette demande")
    end
  end
end
