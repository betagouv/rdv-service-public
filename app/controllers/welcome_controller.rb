class WelcomeController < ApplicationController
  def super_admin
    redirect_to super_admins_agents_path if current_super_admin
  end
end
