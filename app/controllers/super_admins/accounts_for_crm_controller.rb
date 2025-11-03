module SuperAdmins
  class AccountsForCrmController < SuperAdmins::ApplicationController
    def index
      @accounts_for_crm = policy_scope(Territory.where(category: ["", nil]), policy_scope_class: SuperAdmin::TerritoryPolicy::Scope)

      # le module Administrate::Punditize oblige à faire un appel à #authorize même si on est sur l'index
      authorize(@accounts_for_crm, policy_class: SuperAdmin::TerritoryPolicy)
    end
  end
end
