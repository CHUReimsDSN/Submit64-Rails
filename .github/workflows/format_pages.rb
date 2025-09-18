require 'fileutils'

folder_path = "./docs/"

Dir.glob("#{folder_path}*.md").sort.each_with_index do |file, index|
content = File.read(file)
if File.basename(file) == 'index.md'
  nav_order = 1
else
  nav_order = index + 2
end
content.sub!(/^---\n/, "---\nnav_order: #{nav_order}\nlayout: default\n")
File.write(file, content)
end
