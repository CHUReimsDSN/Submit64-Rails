# generate YARD doc
bundle exec yard doc --no-output
bundle exec rake docs

# run doc server
bundle exec jekyll serve --source docs

# build doc for github actions
bundle exec jekyll build --source docs --destination _site
