module SuperAdmins
  class OauthApplicationsController < SuperAdmins::ApplicationController
    # Le client_secret n'est consultable qu'une seule fois, à la création :
    # on l'affiche dans le flash de redirection (le secret est hashé en base).
    def create
      resource = new_resource(resource_params)
      authorize_resource(resource)

      if resource.save
        notice = "#{translate_with_resource('create.success')} — client_id : #{resource.uid}"
        notice += " — client_secret (affiché une seule fois, à transmettre au partenaire par canal sécurisé) : #{resource.plaintext_secret}"
        redirect_to(after_resource_created_path(resource), notice:)
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource),
        }, status: :unprocessable_entity
      end
    end

    # Rotation du client_secret : régénère le secret (affiché une seule fois dans le flash)
    # et révoque tous les jetons actifs de l'application
    def regenerate_secret
      application = requested_resource
      application.renew_secret
      application.save!
      application.access_tokens.find_each(&:revoke)

      redirect_to(
        super_admins_oauth_application_path(application),
        notice: "Nouveau client_secret (affiché une seule fois, à transmettre au partenaire par canal sécurisé) : #{application.plaintext_secret}"
      )
    end
  end
end
