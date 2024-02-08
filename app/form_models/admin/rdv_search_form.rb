class Admin::RdvSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_id, :status, :motif_id, :scoped_organisation_id

  memoize def organisation
    if scoped_organisation_id.present?
      Organisation.find(scoped_organisation_id)
    elsif organisation_id.present?
      Organisation.find(organisation_id)
    end
  end

  memoize def agent
    Agent.find(agent_id) if agent_id.present?
  end

  memoize def user
    User.find(user_id) if user_id.present?
  end

  memoize def lieu
    Lieu.find(lieu_id) if lieu_id.present?
  end

  def to_query
    %i[organisation_id start end agent_id user_id status lieu_id motif_id scoped_organisation_id]
      .map { [_1, send(_1)] }.to_h
  end
end
