class Admin::UserSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :agent_id, :search

  def organisation
    @organisation ||= Organisation.find(organisation_id) if organisation_id.present?
  end

  def agent
    @agent ||= Agent.find(agent_id) if agent_id.present?
  end

  def users
    users = User.within_organisation(organisation)
    users = users.with_referent(agent) if agent.present?
    users = users.search_by_text(search) if search.present?
    users
  end

  def to_query
    %i[organisation_id agent_id search]
      .map { [_1, send(_1)] }.to_h
  end
end
