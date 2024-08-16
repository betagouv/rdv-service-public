class Users::CreneauxSearch
  include Users::CreneauxSearchConcern

  attr_reader :motif, :date_range, :user, :lieu

  delegate :start_booking_delay, :end_booking_delay, to: :motif

  def initialize(user:, motif:, lieu:, date_range: nil, geo_search: nil)
    @user = user
    @motif = motif
    @lieu = lieu
    @date_range = date_range
    @geo_search = geo_search
  end

  def self.creneau_for(user:, motif:, lieu:, starts_at:, geo_search: nil)
    search = new(
      user: user,
      motif: motif,
      lieu: lieu,
      date_range: (starts_at.to_date..(starts_at + 1.day).to_date),
      geo_search: geo_search
    )

    search.creneaux.select { _1.starts_at == starts_at }.sample
  end
end
