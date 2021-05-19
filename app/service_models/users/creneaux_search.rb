# frozen_string_literal: true

class Users::CreneauxSearch
  include Users::CreneauxSearchConcern

  attr_reader :motif, :date_range

  def initialize(user:, motif:, lieu:, date_range:, geo_search: nil)
    @user = user
    @motif = motif
    @lieu = lieu
    @date_range = date_range
    @geo_search = geo_search
  end
end
