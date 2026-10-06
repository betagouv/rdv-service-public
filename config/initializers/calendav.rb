# Certains serveurs CalDAV encodent les caractères hors du plan multilingue de base (notamment les emojis)
# sous forme de paires de substitution UTF-16 en références de caractères XML, par exemple
# « &#55357;&#56525; » au lieu de « &#128205; » pour 📍.
# Ces références sont invalides en XML et font échouer le parsing strict de Nokogiri
# (« xmlParseCharRef: invalid xmlChar value 55357 »).
# On recombine donc chaque paire en un seul code point avant de parser la réponse.
module CalendavSurrogatePairsFix
  HIGH_SURROGATE = "(?:&#(?<high_dec>5[5-6]\\d{3});|&#x(?<high_hex>[dD][89abAB][0-9a-fA-F]{2});)".freeze
  LOW_SURROGATE = "(?:&#(?<low_dec>5[6-7]\\d{3});|&#x(?<low_hex>[dD][c-fC-F][0-9a-fA-F]{2});)".freeze
  SURROGATE_PAIR_REGEX = /#{HIGH_SURROGATE}#{LOW_SURROGATE}/

  def self.fix(xml)
    return xml unless xml.is_a?(String) && xml.include?("&#")

    xml.gsub(SURROGATE_PAIR_REGEX) do
      match = Regexp.last_match
      high = match[:high_dec] ? match[:high_dec].to_i : match[:high_hex].to_i(16)
      low = match[:low_dec] ? match[:low_dec].to_i : match[:low_hex].to_i(16)

      if high.between?(0xD800, 0xDBFF) && low.between?(0xDC00, 0xDFFF)
        "&#x#{(0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00)).to_s(16)};"
      else
        match[0]
      end
    end
  end

  private

  def parse(string)
    super(CalendavSurrogatePairsFix.fix(string))
  end
end

Calendav::Parsers::ResponseXML.prepend(CalendavSurrogatePairsFix)
