module SuperAdmins
  class AgentRolesController < SuperAdmins::ApplicationController
    def destroy
      if requested_resource.destroy
        flash[:notice] = translate_with_resource("destroy.success")
      else
        flash[:error] = requested_resource.errors.full_messages.join("<br/>")
      end

      redirect_to(after_resource_created_path(requested_resource.agent), notice: flash[:notice])
    end
  end
end
