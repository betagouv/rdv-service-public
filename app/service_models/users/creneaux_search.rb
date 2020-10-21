class Users::CreneauxSearch
  include Users::CreneauxSearchConcern

  attr_reader :motifs, :date_range

  def initialize(user:, motifs:, lieu:, date_range:)
    @user = user
    @motifs = motifs
    @lieu = lieu
    @date_range = date_range
  end

  protected

  def motif_location_type
    nil
  end
end
