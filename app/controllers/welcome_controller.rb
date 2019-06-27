class WelcomeController < ApplicationController
  layout 'landing'

  def index
    render layout: 'welcome'
  end

  def welcome_pro; end
end
