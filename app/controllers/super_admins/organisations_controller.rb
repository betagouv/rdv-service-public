module SuperAdmins
  class OrganisationsController < SuperAdmins::ApplicationController
    def past_plage_ouvertures
      org = Organisation.find(params[:organisation_id])
      authorize(org, policy_class: SuperAdmin::OrganisationPolicy)
      plage_ouvertures = org.plage_ouvertures.expired
      count = plage_ouvertures.count
      plage_ouvertures.each(&:destroy!)
      redirect_to super_admins_organisation_path(org.id), flash: { success: "#{count} plages d’ouverture ont été supprimées" }
    end
  end
end
