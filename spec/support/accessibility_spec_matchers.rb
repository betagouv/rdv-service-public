class AxeRunner
  attr_reader :page

  Violation = Data.define(:id, :impact, :tags, :description, :help, :helpUrl) do
    def to_s
      <<~MSG
        # #{description}

        impact #{impact} · #{help}
        #{id} · #{tags.join(', ')}
        #{helpUrl}
      MSG
    end
  end

  def initialize(page)
    unless page.driver.is_a?(Capybara::Playwright::Driver)
      raise ArgumentError, "make sure to use the playwright driver with this matcher"
    end

    @page = page
  end

  def violations
    @violations ||= raw_results
      .fetch("violations")
      .map do |json|
        # omitting nodes because it clutters up the output
        Violation.new(**json.except("nodes"))
      end
  end

  # inject the axe JS into the page, wait for the results to be logged, parse the results, and return them
  def raw_results
    @raw_results ||= begin
      axe_results_console_message =
        page.driver.with_playwright_page do |playwright_page|
          playwright_page.expect_console_message(
            predicate: method(:console_message_contains_axe_results?)
          ) do
            playwright_page.add_script_tag(path: Rails.root.join("node_modules/axe-core/axe.min.js"))
            page.evaluate_script("axe.run().then(results => console.log(JSON.stringify(results)));")
          end
        end
      JSON.parse(axe_results_console_message.text)
    end
  end

  # predicate method which identifies the console log that contains the axe results payload
  def console_message_contains_axe_results?(msg)
    JSON.parse(msg.text).dig("testRunner", "name") == "axe"
  rescue StandardError
    false
  end
end

RSpec::Matchers.define :be_axe_clean do
  match do |page|
    @axe_runner = AxeRunner.new(page)
    @axe_runner.violations.empty?
  end

  failure_message { |_page| <<~MSG }
    Expected no axe violations, found #{@axe_runner.violations.count} :

    #{@axe_runner.violations.map(&:to_s).join("\n\n")}
  MSG
end
