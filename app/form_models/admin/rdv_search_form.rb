class Admin::RdvSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_ids, :status, :motif_ids, :scoped_organisation_ids

  memoize def agent
    Agent.find(agent_id) if agent_id.present?
  end

  memoize def user
    User.find(user_id) if user_id.present?
  end

  def to_query
    %i[organisation_id start end agent_id user_id status lieu_ids motif_ids scoped_organisation_ids]
      .map { [_1, send(_1)] }.to_h
  end
end
