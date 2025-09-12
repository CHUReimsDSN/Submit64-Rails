require "yard"
require "fileutils"

YARD::Registry.load!

YARD::Registry.all(:class, :module).each do |obj|
  path = "docs/api/#{obj.path.gsub('::', '/')}.md"
  FileUtils.mkdir_p(File.dirname(path))

  title = obj.path.split("::").last

  File.open(path, "w") do |f|
    f.puts <<~YAML
        ---
        title: #{title}
        parent: API
        layout: default
        has_children: false
        nav_order: 1
        ---
      YAML

    # --- Contenu ---
    f.puts "# #{obj.path}"
    f.puts
    f.puts obj.docstring
    f.puts

    obj.meths.each do |m|
      f.puts "## #{m.name}"
      f.puts m.docstring
      f.puts
    end
  end
end

File.open("docs/api.md", "w") do |f|
  f.puts <<~YAML
      ---
      title: API
      layout: default
      has_children: true
      nav_order: 1000
      ---
    YAML
  f.puts "# API"
  f.puts
  f.puts "Documentation de l’API générée automatiquement."
end