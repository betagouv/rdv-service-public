# frozen_string_literal: true

class Users::CreneauxSearch
  include Users::CreneauxSearchConcern

  attr_reader :motif, :date_range, :user, :lieu

  delegate :start_booking_delay, :end_booking_delay, to: :motif

  def initialize(user:, motif:, lieu:, date_range:, geo_search: nil, agents: [])
    @user = user
    @motif = motif
    @lieu = lieu
    @date_range = date_range
    @geo_search = geo_search
    @agents = agents
  end
end
