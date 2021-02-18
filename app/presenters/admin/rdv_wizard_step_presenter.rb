class Admin::RdvWizardStepPresenter
  include ActionView::Helpers
  include Rails.application.routes.url_helpers

  TITLES = [
    "1. Motif",
    "2. Usager(s)",
    "3. Agent(s), horaires & lieu",
    "4. Notifications"
  ].freeze

  def initialize(rdv_wizard_form)
    @rdv_wizard_form = rdv_wizard_form
  end

  def title
    self.class.title_for(@rdv_wizard_form.step_number)
  end

  def self.title_for(step_number)
    TITLES[step_number - 1]
  end
end
