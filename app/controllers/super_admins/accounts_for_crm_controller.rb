module SuperAdmins
  class AccountsForCrmController < SuperAdmins::ApplicationController
    def index
      @accounts_for_crm = policy_scope(Territory.where(category: ["", nil]), policy_scope_class: SuperAdmin::TerritoryPolicy::Scope)

      # le module Administrate::Punditize oblige à faire un appel à #authorize même si on est sur l'index
      authorize(@accounts_for_crm, policy_class: SuperAdmin::TerritoryPolicy)
    end

    def edit
      @territory = Territory.find(params[:id])
      authorize(@territory, policy_class: SuperAdmin::TerritoryPolicy)
    end

    def update
      @territory = Territory.find(params[:id])
      authorize(@territory, policy_class: SuperAdmin::TerritoryPolicy)

      @territory.assign_attributes(params.require(:territory).permit(:category))

      authorize(@territory, policy_class: SuperAdmin::TerritoryPolicy)

      if @territory.save
        flash[:success] = "Catégorie ajoutée à l'espace"
        redirect_to super_admins_accounts_for_crm_index_path
      else
        render :edit
      end
    end
  end
end
