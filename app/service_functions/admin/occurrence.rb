module Admin::Occurrence
  def self.extract_from(elements, period)
    return [] unless elements.is_a?(Array)
    return [] unless elements.map { |e| e.respond_to?(:occurences_for) }.uniq == [true]

    elements.flat_map do |element|
      element.occurences_for(period).map { |occurrence| [element, occurrence] }
    end.sort_by(&:second)
  end
end
