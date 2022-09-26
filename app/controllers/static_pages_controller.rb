# frozen_string_literal: true

class StaticPagesController < ApplicationController
  def mds
    redirect_to root_path unless current_domain == Domain::RDV_SOLIDARITES
  end

  def accessibility; end

  def contact; end

  def domaines; end

  def health_check
    Territory.count # check connection to DB is working
  end

  def presentation_for_agents
    render current_domain.presentation_for_agents_template_name
  end
end
