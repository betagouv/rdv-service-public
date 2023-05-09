# frozen_string_literal: true

module AccessibilityChecks
  def visit(path)
    super
    expect(page).to be_axe_clean
  end
end
