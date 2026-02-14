class UserRdvWizard
  include RdvBuilderConcern

  def initialize(user, attributes)
    @user = user
    build_rdv_from_attributes(attributes)
  end
end
