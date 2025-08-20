require_relative "justicefr/official_lieu"

class JusticeLieuxMatcher
  def initialize
    @lieux_by_code_postal = {}
    @official_matches_by_code_postal = {}
  end

  def match
    puts "Nombre de code postaux total"
    puts all_code_postaux.count

    # one_to_one_matches
    # one_local_to_many_official_matches
    # many_local_to_one_official_matches
    many_to_many_matches
  end

  private

  def one_to_one_matches
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
      puts(line.formatted_address)
      puts lieu.address

      puts "\n========\n"

      puts "Leur noms :"
      puts line["titre"]
      puts lieu.name

      puts "Est-ce que ces deux lieux correspondent ? (y/n)"
      response = gets.chomp

      if response["y"]
        JusticeLieuxMatch.create(ee_id: line.ee_id, lieu: lieu)
        puts "Match créé !"
      end
    end
  end

  def one_local_to_many_official_matches
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

      puts ">>>  #{line.formatted_address}      :      #{line['titre']}\n\n"

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
  end

  def many_local_to_one_official_matches
    code_postaux_with_multiple_distant_matches = all_code_postaux.select do |code_postal|
      official_matches(code_postal).count > 1
    end.select do |code_postal|
      local_matches(code_postal).count == 1
    end

    total = code_postaux_with_multiple_distant_matches.count

    code_postaux_with_multiple_distant_matches.each.with_index do |code_postal, index|
      puts "Progrès : #{index}/#{total}"

      lieu = local_matches(code_postal).first

      puts "\n\n\n"
      puts "#{lieu.address}            : #{lieu.name}"

      official_lieux = official_matches(code_postal)

      official_lieux.each.with_index do |official_lieu, i|
        puts "#{i + 1} ) #{official_lieu.formatted_address}            :  #{official_lieu.titre}  (#{official_lieu.ee_id})"
      end

      puts "\nQuel lieux correspond ? (entrez 0 pour aucun)"
      response = gets.chomp

      official_lieu = official_lieux[response.to_i - 1]

      if response != "0"
        JusticeLieuxMatch.create(ee_id: official_lieu.ee_id, lieu: lieu)
        puts "Match créé !"
      end
    end
  end

  def many_to_many_matches
    codes_postaux = all_code_postaux.select do |code_postal|
      official_matches(code_postal).count > 1
    end.select do |code_postal|
      local_matches(code_postal).count > 1
    end

    total = codes_postaux.count

    codes_postaux.each.with_index do |code_postal, index|
      puts "\n\n\n\n\n"
      puts "Progrès : #{index}/#{total}"

      official_lieux = official_matches(code_postal)

      official_lieux.each.with_index do |official_lieu, i|
        puts "#{i + 1} ) #{official_lieu.formatted_address}            :  #{official_lieu.titre}  (#{official_lieu.ee_id})"
      end

      puts "======================"

      local_lieux = local_matches(code_postal)
      local_lieux.each.with_index do |lieu, i|
        puts "#{i + 1} )  #{lieu.address}      :      #{lieu.name} (#{lieu.id}) (#{lieu.rdvs.count} rdvs) (organisation #{lieu.organisation_id})"
      end

      gets.chomp
    end
  end

  def all_code_postaux
    official_lieux_with_possible_matches.map(&:code_postal).uniq
  end

  def official_matches(code_postal)
    result = @official_matches_by_code_postal[code_postal]
    if result.nil?
      @official_matches_by_code_postal[code_postal] = official_lieux_with_possible_matches.select do |line|
        line.code_postal == code_postal
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
      local_matches(line.code_postal).any?
    end
  end

  def cdad_lieux_in_csv
    Justicefr::OfficialLieu.all.select do |csv_line|
      csv_line["type-organisme"].start_with?("asj-") && csv_line.adresse
    end
  end
end

JusticeLieuxMatcher.new.match
