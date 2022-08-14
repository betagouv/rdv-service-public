# frozen_string_literal: true

class WelcomeController < ApplicationController
  # TODO: déplacer ces action dans `StaticPagesController`
  def welcome_agent
    # La page de bienvenue MDS est seulement à afficher pour RDV-S, pas RDV-IN
    redirect_to agent_session_path unless current_domain.default?
  end

  def super_admin; end
end
