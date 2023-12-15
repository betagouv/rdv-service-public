module SuperAdmins
  class AgentRolesController < SuperAdmins::ApplicationController
    def after_resource_destroyed_path(requested_resource)
      [namespace, requested_resource.agent]
    end
  end
end
