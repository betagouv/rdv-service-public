# rails runner scripts/replace_string_in_file_names.rb "expression_to_replace" "replace_with"
# Ce script renomme tous les dossiers et fichiers contenant la première expression en la remplaçant
# par la deuxième expression. C'est utile notamment lorsqu'on renomme une table

def replace_string_in_file_names(file_names, expression_to_replace, replace_with)
  file_names
    .select { |file_name| file_name.include?(expression_to_replace) }
    .each do |file_name|
      new_file_name = file_name.gsub(expression_to_replace, replace_with)
      FileUtils.mv(file_name, new_file_name)
    end
end

expression_to_replace = ARGV[0]
replace_with = ARGV[1]

[
  [expression_to_replace, replace_with],
  [expression_to_replace.capitalize, replace_with.capitalize],
  [expression_to_replace.upcase, replace_with.upcase],
].each do |being_replaced, replacing|
  folder_names = Dir.glob("app/**/**/") + Dir.glob("spec/**/**/") + Dir.glob("config/**/**/")
  replace_string_in_file_names(folder_names, being_replaced, replacing)
  file_names = Dir.glob("app/**/*") + Dir.glob("spec/**/*") + Dir.glob("config/**/*")
  replace_string_in_file_names(file_names, being_replaced, replacing)
end
