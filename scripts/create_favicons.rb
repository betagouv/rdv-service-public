#!/usr/bin/env ruby

# cf app/views/common/_favicon.html.erb

SIZE = 64
BACKGROUND_COLOR = "#1D2A5C".freeze

variants = [
  { file_name: "favicon-demo-#{SIZE}x#{SIZE}.png", sub_text: "DEMO", sub_text_color: "#FFD700", sub_text_pointsize: 20 },
  { file_name: "favicon-staging-#{SIZE}x#{SIZE}.png", sub_text: "STAGING", sub_text_color: "#FFD700", sub_text_pointsize: 15 },
  { file_name: "favicon-pr-#{SIZE}x#{SIZE}.png", sub_text: "PR", sub_text_color: "#FFD700", sub_text_pointsize: 28 },
  { file_name: "favicon-dev-#{SIZE}x#{SIZE}.png", sub_text: "DEV", sub_text_color: "#00E676", sub_text_pointsize: 24 },
]

variants.each do |variant|
  output_path = File.join(__dir__, "..", "public", variant[:file_name])
  system(<<~CMD)
    magick -size #{SIZE}x#{SIZE} xc:'#{BACKGROUND_COLOR}' \
      -font Helvetica-Bold \
      -fill white -pointsize 26 -gravity north -annotate +0+6 'RDV' \
      -fill '#{variant[:sub_text_color]}' -pointsize #{variant[:sub_text_pointsize]} -gravity south -annotate +0+2 '#{variant[:sub_text]}' \
      #{output_path}
  CMD
  puts "Created #{output_path} ✅"
end

puts "\nFinished 🏁 clear your browser cache"
