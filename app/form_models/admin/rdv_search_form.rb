# frozen_string_literal: true

class Admin::RdvSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_id, :status, :show_user_details, :motif_id

  def organisation
    @organisation ||= Organisation.find(organisation_id) if organisation_id.present?
  end

  def agent
    @agent ||= Agent.find(agent_id) if agent_id.present?
  end

  def user
    @user ||= User.find(user_id) if user_id.present?
  end

  def lieu
    @lieu ||= Lieu.find(lieu_id) if lieu_id.present?
  end

  def to_query
    %i[organisation_id start end agent_id user_id status show_user_details lieu_id motif_id]
      .map { [_1, send(_1)] }.to_h
  end
end
