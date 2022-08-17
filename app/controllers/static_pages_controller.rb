# frozen_string_literal: true

class StaticPagesController < ApplicationController
  def mds
    redirect_to root_path unless current_domain == Domain::RDV_SOLIDARITES
  end

  def accessibility; end

  def contact; end

  def domaines; end

  def rdv_solidarites_presentation_for_agents
    redirect_to agent_session_path unless current_domain == Domain::RDV_SOLIDARITES
  end
end
