module Admin::Occurrence
  def self.extract_from(elements, period)
    elements.flat_map do |element|
      element.occurences_for(period).map { |occurrence| [element, occurrence] }
    end.sort_by(&:second)
  end
end
