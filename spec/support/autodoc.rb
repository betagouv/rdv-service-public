# Autodoc, la doc automatique !
class Autodoc
  @scenarios = []

  def self.start_scenario(title, example)
    scenario = Scenario.new(title, example)
    @scenarios << scenario
    scenario
  end

  def self.render
    `mkdir -p tmp/capybara/autodoc`

    @scenarios.each do |scenario|
      Rails.root.join("tmp/capybara/autodoc/scenario_#{scenario.index}.html").write(
        Slim::Template.new(Rails.root.join("spec/support/autodoc/layout.html.slim")).render(scenario) do
          Slim::Template.new(Rails.root.join("spec/support/autodoc/scenario.html.slim")).render(scenario).html_safe # rubocop:disable Rails/OutputSafety
        end
      )
    end

    Rails.root.join("tmp/capybara/autodoc/index.html").write(
      Slim::Template.new(Rails.root.join("spec/support/autodoc/layout.html.slim")).render(self) do
        Slim::Template.new(Rails.root.join("spec/support/autodoc/index.html.slim")).render(self).html_safe # rubocop:disable Rails/OutputSafety
      end
    )

    if @scenarios.any?
      puts "La doc est accessible sur file://#{Rails.root.join('tmp/capybara/autodoc/index.html')}"
    end
  end

  class Scenario
    def initialize(title, example)
      @title = title
      @index = Digest::SHA1.hexdigest(title)[0..8]
      @example = example
      @sections = []
      @current_section = nil
    end

    attr_reader :title, :index

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
      `mkdir -p tmp/capybara/autodoc`

      path = Rails.root.join("tmp/capybara/autodoc/#{filename}")

      if page_or_email.is_a?(Capybara::Node::Email)
        Capybara.current_session.driver.visit "file://#{page_or_email.save_page}"
        Capybara.current_session.driver.browser.save_screenshot(path)
      else
        page_or_email.driver.browser.save_screenshot(path)
      end

      img_src = ENV["UPLOAD_TO_GH_PAGES"] ? "/rdv-service-public/#{filename}" : path

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
