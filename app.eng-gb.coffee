axis         = require 'axis'
rupture      = require 'rupture'
autoprefixer = require 'autoprefixer-stylus'
js_pipeline  = require 'js-pipeline'
css_pipeline = require 'css-pipeline'
W            = require 'when'
node         = require 'when/node'
request      = require 'request'
records      = require 'roots-records'
moment       = require 'moment'


content_url  = 'http://qa-inmarsat.za.prk-host.net/repos/unicore-cms-content-mama-ke-prod'
models_url   = "#{content_url}/unicore.content.models"

slugify = (s) ->
  s.toLowerCase().replace(/(\s|\_)/g, '-').trim()

retrieve_models = (model) ->
  "#{models_url}.#{model}.json"

current_locale = 'eng_GB'

filter_current_locale = (collectionItem) ->
  collectionItem.language is current_locale

module.exports =
  ignores: ['readme.md', '**/layout.*', '**/_*', '.gitignore', 'ship.*conf']

  locals:
    current_locale: current_locale
    current_locale_isocode: 'en'
    collections: {}
    articles_path: "/lang/#{slugify(current_locale)}/articles"
    category_path: "/lang/#{slugify(current_locale)}/articles/category"
    slugify: slugify
    moment: moment
    locales: [{
      name: 'English',
      locale: 'eng_GB',
      href: '/lang/eng-gb'
    }, {
      name: 'Kiswahili',
      locale: 'swa_KE',
      href: '/lang/swa-ke'
    }]

  output: 'public/lang/eng-gb'

  extensions: [
    records
      locales:
        url: retrieve_models 'Localisation'
      categories:
        url: retrieve_models 'Category'
        template: 'views/_category.jade'
        collection: (categories) ->
          categories = categories.filter filter_current_locale
        out: (category) ->
          "/articles/category/#{category.slug}"
        hook: (categories) ->
          categories = categories.filter filter_current_locale
      pages: 
        url: retrieve_models 'Page'
        template: 'views/_page.jade'
        collection: (pages) ->
          # filter out any pages that aren't in English
          pages.filter filter_current_locale
        out: (page) ->
          "/articles/#{page.slug}"
        hook: (pages) ->
          # filter out any pages that aren't in English
          pages = pages.filter filter_current_locale
          # replace any linked page IDs with titles and slugs
          pages = pages.map (page) ->
            if page.linked_pages?.length
              page.linked_pages = page.linked_pages.map (uuid) ->
                recommended = {}
                for linked_page in pages when linked_page.uuid is uuid
                  recommended.title = linked_page.title
                  recommended.slug  = linked_page.slug
                  recommended.description = linked_page.description
                  break
                recommended
            page
    js_pipeline(files: 'assets/js/*.coffee'),
    css_pipeline(files: 'assets/css/*.styl', minify: true)
  ]

  stylus:
    use: [axis(), rupture(), autoprefixer()]

  # this is extremely hacky, but this little project gave Roots its biggest
  # workout ever! Who'da thought? This will have to do while we figure out
  # how to get the `roots-records` extension to handle this kind of project
  # more elegantly in the future.
  # (what's going on here you ask? I'm downloading the JSON content from
  # the hosted API in parrallel and setting it on the template engine locals
  # in a "before compile" lifecycle hook and filtering out the unnecessary locale)
  before: (roots) ->
    W.map(['Category', 'Page', 'Localisation'], (model) ->
      node.call request.get.bind(request), retrieve_models(model)
        .spread (response, body) ->
          W.try(JSON.parse, body)
        .then (body) ->
          roots.config.locals.collections[model] = body.filter (item) ->
            item.language is current_locale
        .done()
    ).done null, (err) -> throw err
