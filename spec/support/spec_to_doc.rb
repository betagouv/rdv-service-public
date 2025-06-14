class SpecToDoc
  @scenarios = {}

  def self.start_scenario(title, example)
    @scenarios[title] = Scenario.new(title, @scenarios.length, example)
  end

  def self.render
    `mkdir -p tmp/capybara/spec_to_doc`

    @scenarios.values.each.with_index do |scenario, i|
      Rails.root.join("tmp/capybara/spec_to_doc/scenario_#{i}.html").write(scenario.render)
    end

    Rails.root.join("tmp/capybara/spec_to_doc/index.html").write(
      Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/layout.html.slim")).render(self) do
        Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/index.html.slim")).render(self).html_safe # rubocop:disable Rails/OutputSafety
      end
    )

    if ENV["UPLOAD_TO_SURGE"]
      branch_name = `git rev-parse --abbrev-ref HEAD`.strip
      domain_name = "rdv-service-public-#{branch_name}.surge.sh"
      puts "running yarn run surge tmp/capybara/spec_to_doc #{domain_name}"
      `yarn run surge tmp/capybara/spec_to_doc #{domain_name}`

      puts "La documentation est disponible sur https://#{domain_name}"
    end
  end

  class Scenario
    def initialize(title, index, example)
      @title = title
      @index = index
      @example = example
      @steps = []
    end

    def add_text(description)
      @steps << {
        text: description,
      }
    end

    def add_screenshot(page, text: nil, wait_for: nil)
      if wait_for
        @example.expect(page).to(@example.have_content(wait_for))
      end

      filename = "scenario_#{@index}_step_#{@steps.count}.png"
      `mkdir -p tmp/capybara/spec_to_doc`

      path = Rails.root.join("tmp/capybara/spec_to_doc/#{filename}")

      page.driver.browser.save_screenshot(path)

      img_src = ENV["UPLOAD_TO_SURGE"] ? "/#{filename}" : path

      @steps << { text: text, img_src: img_src }
    end

    def render
      Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/layout.html.slim")).render(self) do
        Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/scenario.html.slim")).render(self).html_safe # rubocop:disable Rails/OutputSafety
      end
    end
  end
end
