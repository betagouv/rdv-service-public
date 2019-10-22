module Admin
  class OrganisationsController < Admin::ApplicationController
    def default_configuration
      Motif.where(organisation_id: 1).map(&:dup).each { |m| m.organisation_id = requested_resource.id }.map(&:save)
      redirect_to(
        [namespace, requested_resource],
        notice: "La configuration par défaut a été appliquée."
      )
    end
  end
end
