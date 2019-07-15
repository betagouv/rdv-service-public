module PlageOuverturesHelper
  def time_collections
    (7..19).flat_map do |h|
      padded_h = format("%02i", h)
      (0..55).step(5).map do |m|
        padded_min = format("%02i", m)
        "#{padded_h}:#{padded_min}"
      end
    end
  end
end
