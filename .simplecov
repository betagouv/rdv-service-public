SimpleCov.start "rails" do
  add_group "Blueprints", "app/blueprints"
  add_group "Controllers", "app/controllers"
  add_group "Form Models", "app/form_models"
  add_group "Helpers", "app/helpers"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Models", "app/models"
  add_group "Policies", "app/policies"
  add_group "Presenters", "app/presenters"
  add_group "Services", "app/services"

  command_name ["tests", ENV["SIMPLECOV_TEST_NAME"], ENV["TEST_ENV_NUMBER"]].compact.join(":")

  if ENV['CI']
    # sur la CI les tests génèrent des rapports JSON ensuite fusionnés vers un rapport HTML
    formatter SimpleCov::Formatter::SimpleFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter
    ])
  end
end
