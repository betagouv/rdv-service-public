class WelcomeController < ApplicationController
  layout 'welcome'

  def index; end

  def welcome_agent
    render layout: 'welcome_agent'
  end
end
