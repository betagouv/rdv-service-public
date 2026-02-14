class UserRdvWizard
  include RdvBuilderConcern

  def initialize(user, attributes)
    @user = user
    build_rdv_from_attributes(attributes)
  end

  def display_france_connect?
    motif.organisation.online_booking_for_particuliers
  end

  def display_pro_connect?
    motif.organisation.online_booking_for_professionnels
  end
end
