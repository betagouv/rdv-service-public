# frozen_string_literal: true

module SuperAdmins
  class LieuxController < SuperAdmins::ApplicationController
    # On modifie cette action pour pouvoir mettre une valeur par défaut en availability
    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      lieu = Lieu.new(resource_params)
      lieu.availability = :enabled

      lieu.save

      if lieu.errors.any?
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource),
        }
      else
        redirect_to(
          [namespace, resource],
          notice: translate_with_resource("create.success")
        )
      end
    end
  end
end
