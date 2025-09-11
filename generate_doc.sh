# generate YARD doc
bundle exec yard doc --no-output
bundle exec rake docs

# run doc server
bundle exec jekyll serve --source docs
