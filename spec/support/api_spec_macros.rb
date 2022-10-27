# frozen_string_literal: true

module ApiSpecMacros
  def with_examples
    after do |example|
      content = example.metadata[:response][:content] || {}
      example_spec = {
        "application/json" => {
          examples: {
            example: {
              value: response.body.present? ? JSON.parse(response.body, symbolize_names: true) : "",
            },
          },
        },
      }
      example.metadata[:response][:content] = content.deep_merge(example_spec)
    end
  end
end
