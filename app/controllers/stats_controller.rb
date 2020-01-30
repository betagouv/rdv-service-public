class StatsController < ApplicationController
  layout 'landing'

  def index
    @rdvs = Rdv.all
    @users = User.active
  end
end
