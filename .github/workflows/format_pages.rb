require 'fileutils'

folder_path = "./docs/"

Dir.glob("#{folder_path}*.md").sort.each_with_index do |file, index|
  content = File.read(file)

  nav_order = File.basename(file) == 'index.md' ? 1 : index + 2

  if content =~ /^---\n/
    content.sub!(/^---\n/, "---\nnav_order: #{nav_order}\nlayout: default\n")
  else
    content = "---\nnav_order: #{nav_order}\nlayout: default\n---\n\n" + content
  end

  toc_entries = content.scan(/^## (.+)/)
  if toc_entries.size >= 2
    toc = ["\n## Table des matières", "{: .no_toc .text-delta }", ""]
    toc_entries.each_with_index do |entry, index_entry|
      toc << "#{index_entry}. #{entry.first}"
    end
    toc << "{:toc}"
    toc << ""

    if content =~ /^# .+/
      content.sub!(/(^# .+\n)/, "\\1#{toc.join("\n")}\n")
    else
      # Si pas de titre principal, ajouter le TOC après le front matter
      parts = content.split(/^---\s*$/, 3)
      if parts.length >= 3
        content = "#{parts[0]}---#{parts[1]}---\n#{toc.join("\n")}\n#{parts[2]}"
      else
        content = "#{content}\n#{toc.join("\n")}"
      end
    end
  end

  File.write(file, content)
end