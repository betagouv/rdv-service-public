Capybara.register_driver :desktop do |capybara_app|
  Capybara::Selenium::Driver.new(
    capybara_app,
    browser: :firefox,
    options: Selenium::WebDriver::Firefox::Options.new(args: %w[--headless --width=1280 --height=1024])
  )
end

class SpecToDoc
  @scenarios = {}

  def self.build_scenario(title)
    @scenarios[title] = Scenario.new(title, @scenarios.length)
  end

  def self.render
    rendered_scenarios = @scenarios.values.map(&:render)

    `mkdir -p tmp/capybara/spec_to_doc`
    rendered_scenarios.each.with_index do |scenario_content, i|
      Rails.root.join("tmp/capybara/spec_to_doc/scenario_#{i}.html").write(scenario_content)
    end

    Rails.root.join("tmp/capybara/spec_to_doc/index.html").write(
      @scenarios.keys.map.with_index.map do |title, i|
        "<a href='scenario_#{i}.html'>#{title}</a>"
      end.join("<br />")
    )
  end

  class Scenario
    def initialize(title, index)
      @title = title
      @index = index
      @steps = []
    end

    def add_text(description)
      @steps << description
    end

    def add_screenshot(page)
      filename = "scenario_#{@index}_step_#{@steps.count}.png"
      `mkdir -p tmp/capybara/spec_to_doc`
      path = Rails.root.join("tmp/capybara/spec_to_doc/#{filename}")
      @steps << { screenshot_path: path }
      page.driver.browser.save_screenshot(path)
    end

    def render
      @steps.map do |step|
        if step.is_a?(String)
          "<p>#{step}</p>"
        else
          "<img src=#{step[:screenshot_path]} width=800 style='border: solid 2px grey'/>"
        end
      end.join("\n")
    end
  end
end
