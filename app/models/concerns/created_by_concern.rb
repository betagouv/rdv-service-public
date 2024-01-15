module CreatedByConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, polymorphic: true, optional: true
  end

  def created_by_agent?
    created_by_type == "Agent"
  end

  def created_by_user?
    created_by_type == "User"
  end

  def created_by_prescripteur?
    created_by_type == "Prescripteur"
  end

  def created_by_external_agent?
    created_by_agent? && created_by && !organisation.in?(created_by.organisations)
  end

  def prescription?
    created_by_prescripteur? || created_by_external_agent?
  end
end
