module DataUtils
  def value_counts(values)
    counts = Hash.new(0)
    values.each { counts[_1] += 1 }
    counts
  end
end
