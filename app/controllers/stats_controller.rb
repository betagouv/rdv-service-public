class StatsController < ApplicationController
  layout 'landing'

  def index
    @rdvs = Rdv.all
  end
end
