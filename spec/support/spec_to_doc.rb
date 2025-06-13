class SpecToDoc
  @scenarios = {}

  def self.start_scenario(title, example)
    @scenarios[title] = Scenario.new(title, @scenarios.length, example)
  end

  def self.render
    rendered_scenarios = @scenarios.values.map(&:render)

    `mkdir -p tmp/capybara/spec_to_doc`
    rendered_scenarios.each.with_index do |scenario_content, i|
      Rails.root.join("tmp/capybara/spec_to_doc/scenario_#{i}.html").write(scenario_content)
    end

    Rails.root.join("tmp/capybara/spec_to_doc/index.html").write(
      (
        [
          "Cette page documente différentes fonctionnalités de RDV Service Public",
        ] +
      @scenarios.keys.map.with_index.map do |title, i|
        "<a href='scenario_#{i}.html'>#{title}</a>"
      end + [
        "Dernière mise à jour le #{I18n.l(Time.zone.now)}",
      ]
      ).join("<br />")
    )
  end

  class Scenario
    def initialize(title, index, example)
      @title = title
      @index = index
      @example = example
      @steps = []
    end

    def add_text(description)
      @steps << "<p>#{description}</p>"
    end

    def add_screenshot(page, wait_for: nil)
      if wait_for
        @example.expect(page).to(@example.have_content(wait_for))
      end

      filename = "scenario_#{@index}_step_#{@steps.count}.png"
      `mkdir -p tmp/capybara/spec_to_doc`
      path = Rails.root.join("tmp/capybara/spec_to_doc/#{filename}")
      page.driver.browser.save_screenshot(path)

      @steps << "<img src=#{path} width=800 style='border: solid 2px grey'/>"
    end

    def add_spacing
      @steps << "<div style='margin-top: 64px'></div>"
    end

    def render
      @steps.join("\n")
    end
  end
end
