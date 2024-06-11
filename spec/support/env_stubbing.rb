# See https://github.com/thoughtbot/climate_control?tab=readme-ov-file#usage

def stub_env_with(options)
  around do |example|
    with_modified_env(options) do
      example.run
    end
  end
end

def with_modified_env(options = {}, &block)
  ClimateControl.modify(options, &block)
end
