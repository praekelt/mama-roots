_            = require 'lodash'
axis         = require 'axis'
jeet         = require 'jeet'
rupture      = require 'rupture'
autoprefixer = require 'autoprefixer-stylus'
css_pipeline = require 'css-pipeline'
fs           = require 'fs'
records      = require 'roots-records'
config_file  = require './config'

current_locale = 'eng_GB'
articles_path  = 'articles'
category_path  = 'articles/category'

pass = (b, a) ->
  a[b][current_locale].collection

module.exports =

  ignores: config_file.ignored_files

  locals: _.defaults config_file.locals, {
    current_locale: current_locale
    articles_path: articles_path
    category_path: category_path
  }

  extensions: [
    records
      categories:
        file: config_file.data_file
        hook: pass.bind null, 'categories'
        template: 'views/_category.jade'
        collection: pass.bind null, 'categories'
        out: (data) -> "#{category_path}/#{data.slug}" 
      pages:
        file: config_file.data_file
        hook: pass.bind null, 'pages'
        template: 'views/_page.jade'
        collection: pass.bind null, 'pages'
        out: (data) -> "#{articles_path}/#{data.slug}"
      recommended_pages:
        file: config_file.data_file
        hook: pass.bind null, 'recommended_pages'
    css_pipeline(files: config_file.css_pipeline_files, out: 'css/build.css', minify: true, hash: true)
  ]

  stylus:
    use: [axis(), jeet(), rupture(), autoprefixer()]

  before: (roots) ->
    data = JSON.parse fs.readFileSync config_file.data_file
    roots.config.locals.navbar_features = data.navbar_features[current_locale].collection
    roots.config.locals.locales = data.locales
