class SpecToDoc
  @scenarios = []

  def self.start_scenario(title, example)
    scenario = Scenario.new(title, @scenarios.length, example)
    @scenarios << scenario
    scenario
  end

  def self.render
    `mkdir -p tmp/capybara/spec_to_doc`

    @scenarios.each.with_index do |scenario, i|
      Rails.root.join("tmp/capybara/spec_to_doc/scenario_#{i}.html").write(
        Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/layout.html.slim")).render(scenario) do
          Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/scenario.html.slim")).render(scenario).html_safe # rubocop:disable Rails/OutputSafety
        end
      )
    end

    Rails.root.join("tmp/capybara/spec_to_doc/index.html").write(
      Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/layout.html.slim")).render(self) do
        Slim::Template.new(Rails.root.join("spec/support/spec_to_doc/index.html.slim")).render(self).html_safe # rubocop:disable Rails/OutputSafety
      end
    )
  end

  def self.upload_to_surge
    branch_name = `git rev-parse --abbrev-ref HEAD`.strip
    domain_name = "rdv-service-public-#{branch_name}.surge.sh"
    puts "running yarn run surge tmp/capybara/spec_to_doc #{domain_name}"
    `yarn run surge tmp/capybara/spec_to_doc #{domain_name}`

    puts "La documentation est disponible sur https://#{domain_name}"
  end

  class Scenario
    def initialize(title, index, example)
      @title = title
      @index = index
      @example = example
      @sections = []
      @current_section = nil
    end

    attr_reader :title

    def start_section(title)
      @current_section = Section.new(title)
      @sections << @current_section
    end

    def add_text(description)
      @current_section.steps << { text: description }
    end

    def add_screenshot(page_or_email, text: nil, wait_for: nil)
      if wait_for
        @example.expect(page_or_email).to(@example.have_content(wait_for))
      end

      filename = "scenario_#{@index}_section_#{@sections.count}_step_#{@current_section.steps.count}.png"
      `mkdir -p tmp/capybara/spec_to_doc`

      path = Rails.root.join("tmp/capybara/spec_to_doc/#{filename}")

      if page_or_email.is_a?(Capybara::Node::Email)
        Capybara.current_session.driver.visit "file://#{page_or_email.save_page}"
        Capybara.current_session.driver.browser.save_screenshot(path)
      else
        page_or_email.driver.browser.save_screenshot(path)
      end

      img_src = ENV["UPLOAD_TO_SURGE"] ? "/#{filename}" : path

      @current_section.steps << { text: text, img_src: img_src }
    end
  end

  class Section
    def initialize(title)
      @title = title
      @steps = []
    end

    attr_accessor :title, :steps
  end
end
