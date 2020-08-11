class Agents::DuplicateUsersSuggestionsController < AgentAuthController
  before_action :set_organisation

  SLICE_SIZE = 50000

  def index
    @page = params[:page]&.to_i || 1
    slice_start = (@page - 1) * SLICE_SIZE
    slice = [slice_start, slice_start + SLICE_SIZE]
    result = FindDuplicateUsersSuggestionsService
      .perform_with(
        current_organisation,
        slice: slice,
        hydrate_users: true,
        users_scope: policy_scope(User)
      )
    @duplicate_users_suggestions = result.hits
    @paginatable_combinations = Kaminari
      .paginate_array([], total_count: result.combinations_count)
      .page(@page)
      .per(SLICE_SIZE)
    @pages_left = @paginatable_combinations.total_pages - @page

    return unless request.xhr?

    render(
      partial: "agents/duplicate_users_suggestions/suggestions",
      locals: {
        suggestions: @duplicate_users_suggestions,
        paginatable_combinations: @paginatable_combinations
      }
    )
  end
end
