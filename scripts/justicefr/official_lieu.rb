class Justicefr; end

class Justicefr::OfficialLieu < OpenStruct
  def self.all
    return @all if @all

    raw_csv = Faraday.get("https://git.easter-eggs.org/cc-data/mj-update/-/raw/main/justice-mobile.csv?ref_type=heads").body
    csv_content = CSV.parse(raw_csv, headers: :first_row, col_sep: ";", liberal_parsing: true).map(&:to_h)

    @all = csv_content.map do |line|
      new(line)
    end
  end

  def code_postal
    adresse[/\d{5}/]
  end

  def formatted_address
    (adresse.gsub("\n", ",").gsub(code_postal, "") + ", #{code_postal}").split(", ").tap do |split_address|
      split_address[1].capitalize
    end.join(", ")
  end
end
