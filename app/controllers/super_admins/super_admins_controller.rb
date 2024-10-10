module SuperAdmins
  class SuperAdminsController < SuperAdmins::ApplicationController
    before_action :check_privilege_escalation, only: %i[update]

    def check_privilege_escalation
      not_authorized_to_update if privilege_escalation?
    end

    private

    def not_authorized_to_update
      flash[:error] = "Vous n'êtes pas autorisé à modifier le role de super_admin"
      redirect_to(request.referer)
    end

    def privilege_escalation?
      current_super_admin.support_member? && resource_params[:role] == "legacy_admin"
    end
  end
end
