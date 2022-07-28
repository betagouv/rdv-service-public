# frozen_string_literal: true

class WelcomeController < ApplicationController
  # TODO: déplacer ces action dans `StaticPagesController`
  def welcome_agent
    unless current_domain.default?
      redirect_to agent_session_path
    end
  end

  def super_admin; end
end
