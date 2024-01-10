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

  def prescription?
    return true if created_by_prescripteur?

    organisation.in?(created_by.organisations) if created_by_agent?
  end
end
