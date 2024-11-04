require_relative "fuzz_helpers"

FactoryBot::SyntaxRunner.include(FuzzHelpers)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
