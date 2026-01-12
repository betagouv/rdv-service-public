# Autodoc, la doc automatique !
class Autodoc
  @categories = {}

  def self.start_scenario(title, example, accessibility_checks: true, category: nil)
    scenario = Scenario.new(title, example, accessibility_checks)
    @categories[category] ||= []
    @categories[category] << scenario
    scenario
  end

  def self.render
    return if @categories.empty?

    `mkdir -p tmp/capybara/autodoc`

    @categories.values.flatten.each do |scenario|
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

    puts "La doc est accessible sur file://#{Rails.root.join('tmp/capybara/autodoc/index.html')}"
  end

  class Scenario
    def initialize(title, example, accessibility_checks)
      @title = title
      @index = Digest::SHA1.hexdigest(title)[0..8]
      @example = example
      @scenario_accessibility_checks = accessibility_checks
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

    def add_screenshot(page_or_email, text: nil, wait_for: nil, accessibility_checks: true)
      if wait_for
        @example.expect(page_or_email).to(@example.have_content(wait_for))
      end

      filename = "scenario_#{@index}_section_#{@sections.count}_step_#{@current_section.steps.count}.png"
      `mkdir -p tmp/capybara/autodoc`

      path = Rails.root.join("tmp/capybara/autodoc/#{filename}")

      if page_or_email.is_a?(Capybara::Node::Email)
        Capybara.current_session.driver.visit "file://#{page_or_email.save_page}"
        Capybara.current_session.driver.save_screenshot(path)
      else
        if @scenario_accessibility_checks && accessibility_checks # On peut désactiver ces checks au niveau de tout le scénario ou juste pour ce screenshot
          @example.expect(page_or_email).to @example.be_axe_clean
        end

        current_size = page_or_email.current_window.size
        page_or_email.current_window.resize_to(current_size[0] * 2, current_size[1] * 2)
        page_or_email.execute_script("document.body.style.zoom=2.0")

        page_or_email.driver.save_screenshot(path)

        page_or_email.execute_script("document.body.style.zoom=1.0")
        page_or_email.current_window.resize_to(current_size[0], current_size[1])
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
