module SuperAdmins
  class UsersController < SuperAdmins::ApplicationController
    private

    # Utilise notre index plutôt que la méthode de recherche inefficiente de Administrate
    def filter_resources(resources, search_term:)
      search_term.present? ? resources.search_by_text(search_term) : resources
    end
  end
end
