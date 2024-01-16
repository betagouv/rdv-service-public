module SuperAdmins
  class UserProfilesController < SuperAdmins::ApplicationController
    def after_resource_destroyed_path(requested_resource)
      [namespace, requested_resource.user]
    end
  end
end
