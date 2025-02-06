class StatsController < ApplicationController
  def index; end

  def territories
    @territories = Territory.all
  end
end
