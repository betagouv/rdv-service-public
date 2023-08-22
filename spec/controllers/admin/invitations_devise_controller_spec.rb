# frozen_string_literal: true

RSpec.describe Admin::AgentsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], invitation_accepted_at: nil) }

  before do
    sign_in agent
  end


end
