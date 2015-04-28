var request = require('request');
var W       = require('when');
var node    = require('when/node');
var fs      = require('fs');


var content_url  = 'http://qa-inmarsat.za.prk-host.net/repos/unicore-cms-content-mama-ke-prod';
var models_url   = content_url + "/unicore.content.models"

function slugify(s) {
  return s.toLowerCase().replace(/(\s|\_)/g, '-').trim();
}

function retrieve_models(model) {
  return models_url + '.' + model + ".json"
}

W.map(['Localisation', 'Category', 'Page'], function(model) {
  return node.call(request.get.bind(request), retrieve_models(model))
    .spread(function(response, body) {
      return W.try(JSON.parse, body);
    });
})
  .spread(function(locales, categories, pages) {

    // BEGIN LOCALES
    locales = locales.map(function(locale) {
      // delete the version prop
      delete locale._version;
      if (locale.locale === 'eng_GB') {
        // set some useful info
        locale.isocode = 'en';
        locale.language = 'English';
      }
      if (locale.locale === 'swa_KE') {
        // set some useful info
        locale.isocode = 'sw';
        locale.language = 'Kiswahili';
      }
      // we're done here
      return locale;
    });

    // BEGIN CATEGORIES
    categories = categories.map(function(category) {
      // delete the version prop
      delete category._version;
      // we're done here
      return category;
    }).sort(function(a, b) {
      return a.position - b.position;
    });

    // BEGIN PAGES
    pages = pages.map(function(page) {
      // delete the version prop
      delete page._version;
      // split content into array by newlines
      page.content = page.content.replace(/\r\n\r\n/g, '\n').split('\n');
      // first item in above array is the intro text
      page.intro_text = page.content.shift();
      // wrap each item in the content array in paragraph tags
      page.content = page.content.map(function(block) {
        return '<p>' + block + '</p>';
      // concatenate the array back into a string
      }).join('');
      // assign titles, slugs and descriptions to linked pages
      page.linked_pages = page.linked_pages.map(function(linked_page) {
        pages.forEach(function(page2) {
          if ((page2.language === page.language) &&)
        });
      });
      // we're done here
      return page;
    });

    var data = {
      locales: locales,
      categories: categories,
      pages: pages
    };

    node.call(fs.writeFile, './data.json', JSON.stringify(data, null, 2), 'utf-8');
  })
  .catch(function(error) {
    console.error(error);
  })
  .done();
