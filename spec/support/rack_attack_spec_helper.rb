RSpec.shared_context "enable rack-attack" do
  around do |example|
    Rack::Attack.enabled = true # it is disabled in a before(:suite) in rails_helper.rb
    Rack::Attack.reset! # this clears the recorded count by IP
    example.run
    Rack::Attack.enabled = false
  end
end
