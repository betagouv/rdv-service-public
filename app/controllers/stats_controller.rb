class StatsController < ApplicationController
  layout 'landing'

  def index
    @rdvs = Rdv.active
  end
end
