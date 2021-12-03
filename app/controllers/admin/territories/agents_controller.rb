# frozen_string_literal: true

class Admin::Territories::AgentsController < Admin::Territories::BaseController

  def index
    @agents = current_territory.organisations.flat_map(&:agents)
  end

end

