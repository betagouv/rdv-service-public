module SuperAdmins
  module PaperTrailConcern
    extend ActiveSupport::Concern

    def show
      if params[:id].to_i.zero? # id is a string (the full name of the agent)
        first_name, last_name = params[:id].split
        @requested_resource = resource_class.find_by!("first_name ILIKE ? AND last_name ILIKE ?", first_name, last_name)
        render locals: { page: Administrate::Page::Show.new(dashboard, requested_resource) }
      else # params[:id] is a number (the actual ID of the agent)
        super
      end
    end
  end
end
