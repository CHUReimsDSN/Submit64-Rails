require "yard"

YARD::Registry.load!

YARD::Registry.all(:class, :module).each do |obj|
  path = "docs/api/#{obj.path.gsub('::', '/')}.md"
  FileUtils.mkdir_p(File.dirname(path))

  File.open(path, "w") do |f|
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
