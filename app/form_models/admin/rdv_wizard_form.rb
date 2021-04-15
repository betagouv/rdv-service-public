module Admin::RdvWizardForm
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce
  STEPS = %w[step1 step2 step3 step4].freeze

  def self.title_for(step_number)
    I18n.t("admin_rdv_wizard_form.step#{step_number}.title")
  end
end
