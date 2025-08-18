class JusticeLieuxMatcher
  def initialize
    @lieux_by_code_postal = {}
    @official_matches_by_code_postal = {}
  end

  def match # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    puts "Nombre de code postaux total"
    puts all_code_postaux.count

    puts "Code postaux avec un seul match de chaque côté"

    code_postaux_with_single_match = all_code_postaux.select do |code_postal|
      official_matches(code_postal).count == 1
    end.select do |code_postal|
      local_matches(code_postal).count == 1
    end

    total = code_postaux_with_single_match.count

    code_postaux_with_single_match.each.with_index do |code_postal, index|
      line = official_matches(code_postal).first

      next if JusticeLieuxMatch.find_by(ee_id: line["ee_id"])

      puts "Progrès : #{index}/#{total}"
      puts "\n\nVoici deux lieux: "

      lieu = local_matches(code_postal).first

      puts "Leur adresses :"
      puts(format_official_address(line["adresse"], code_postal))
      puts lieu.address

      puts "\n========\n"

      puts "Leur noms :"
      puts line["titre"]
      puts lieu.name

      puts "Est-ce que ces deux lieux correspondent ? (y/n)"
      response = gets.chomp

      if response["y"]
        JusticeLieuxMatch.create(ee_id: line["ee_id"], lieu: lieu)
        puts "Match créé !"
      end
    end

    code_postaux_with_multiple_local_matches = all_code_postaux.select do |code_postal|
      official_matches(code_postal).count == 1
    end.select do |code_postal|
      local_matches(code_postal).count > 1
    end

    total = code_postaux_with_multiple_local_matches.count
    code_postaux_with_multiple_local_matches.each.with_index do |code_postal, index|
      line = official_matches(code_postal).first

      next if JusticeLieuxMatch.find_by(ee_id: line["ee_id"])

      puts "Progrès : #{index}/#{total}"

      puts "\n\n\n"
      lieux = local_matches(code_postal)

      puts ">>>  #{format_official_address(line['adresse'], code_postal)}      :      #{line['titre']}\n\n"

      lieux.each.with_index do |lieu, i|
        puts "#{i + 1} )  #{lieu.address}      :      #{lieu.name} (#{lieu.id}) (#{lieu.rdvs.count} rdvs) (organisation #{lieu.organisation_id})"
      end

      puts "\nQuel lieux correspond ? (entrez 0 pour aucun)"
      response = gets.chomp

      lieu = lieux[response.to_i - 1]

      if response != "0"
        JusticeLieuxMatch.create(ee_id: line["ee_id"], lieu: lieu)
        puts "Match créé !"
      end
    end

    code_postaux_with_multiple_distant_matches = all_code_postaux.select do |code_postal|
      official_matches(code_postal).count > 1
    end.select do |code_postal|
      local_matches = local_matches(code_postal)
      local_matches.select do |lieu|
        JusticeLieuxMatch.find_by(lieu_id: lieu.id).none?
      end.count == 1
    end

    puts code_postaux_with_multiple_distant_matches.count

    code_postaux_with_multiple_distant_matches.each.with_index do |_code_postal, index|
      puts "Progrès : #{index}/#{total}"
    end
  end

  private

  def format_official_address(adresse, code_postal)
    adresse.gsub("\n", ",").gsub(code_postal, "") + ", #{code_postal}"
  end

  def all_code_postaux
    official_lieux_with_possible_matches.map do |line|
      code_postal(line)
    end.uniq
  end

  def official_matches(code_postal)
    result = @official_matches_by_code_postal[code_postal]
    if result.nil?
      @official_matches_by_code_postal[code_postal] = official_lieux_with_possible_matches.select do |line|
        code_postal(line) == code_postal
      end
    end

    @official_matches_by_code_postal[code_postal]
  end

  def local_matches(code_postal)
    result = @lieux_by_code_postal[code_postal]

    if result.nil?
      @lieux_by_code_postal[code_postal] = lieux.select do |l|
        l.code_postal == code_postal
      end
    end

    @lieux_by_code_postal[code_postal]
  end

  def lieux
    @lieux = Lieu.where(availability: :enabled).joins(organisation: :territory).where("territories.name ilike ?", "CDAD%").where.not(address: nil)
      .where.not(organisations: { territory_id: 3 }).uniq
  end

  def official_lieux_with_possible_matches
    @official_lieux_with_possible_matches = cdad_lieux_in_csv.select do |line|
      local_matches(code_postal(line)).any?
    end
  end

  def code_postal(csv_line)
    csv_line["adresse"][/\d{5}/]
  end

  def cdad_lieux_in_csv
    @cdad_lieux_in_csv ||= csv_content.select do |csv_line|
      csv_line["type-organisme"].start_with?("asj-") && csv_line["adresse"]
    end
  end

  def csv_content
    CSV.parse(raw_csv, headers: :first_row, col_sep: ";", liberal_parsing: true).map(&:to_h)
  end

  def raw_csv
    Rails.cache.fetch("justice:official_lieux_csv", expires_id: 24.hours) do
      Faraday.get("https://git.easter-eggs.org/cc-data/mj-update/-/raw/main/justice-mobile.csv?ref_type=heads").body
    end
  end
end

JusticeLieuxMatcher.new.match
