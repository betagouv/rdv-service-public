class Admin::OnlineBookingMotifsForm
  include ActiveModel::Model

  attr_reader :motif_ids

  def initialize(motif_ids)
    @motif_ids = motif_ids
  end
end
