moment = require 'moment'

module.exports =

  data_file: './_data.json'

  locals:
    moment: moment
    slugify: (s) -> s.toLowerCase().replace(/(\s|\_)/g, '-').trim()

  # environment-specific output directories
  output:
    default: 'public'
    en: 'public/lang/en'
    sw: 'public/lang/sw'

  # CSS pipeline source files
  css_pipeline_files: 'assets/css/*.styl'

  # files that should be ignored by roots
  ignored_files: [
    'readme.md'
    '**/layout.*'
    '**/*.layout.*'
    '**/_*'
    '.gitignore'
    'ship.*conf'
    'public/**'
    'Makefile'
    'config.coffee'
    'license.md'
    'locales/**'
    'partials/**'
    'partials'
    'locales'
  ]
