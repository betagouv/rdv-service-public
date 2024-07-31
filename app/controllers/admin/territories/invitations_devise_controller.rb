class Admin::Territories::InvitationsDeviseController < Devise::InvitationsController
  layout "application_dsfr"

  def new
    @services = current_territory.services
    self.resource = resource_class.new(territories: [current_territory])
    #  authorize_with_legacy_configuration_scope(resource)
    render :new, layout: "application_configuration"
  end
end
