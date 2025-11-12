# heavily inspired by https://github.com/dequelabs/axe-core-gems/issues/418#issuecomment-3084810531

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
      .map { Violation.new(**_1.except("nodes")) } # nodes clutters up the output
  end

  # inject the axe JS into the page, wait for the results to be logged, parse the results, and return them
  def raw_results
    @raw_results ||= JSON.parse(
      page.driver.with_playwright_page do |playwright_page|
        playwright_page.expect_console_message(predicate: method(:console_message_contains_axe_results?)) do
          page.evaluate_script("axe.run().then(results => console.log(JSON.stringify(results)));")
        end
      end.text
    )
  end

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

def expect_page_to_be_axe_clean(path)
  visit path
  expect(page).to have_current_path(path)
  expect(page).to have_title(/.* - RDV Solidarités/)
  expect(page).to be_axe_clean
end
