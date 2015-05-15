/**
 * This file is an attempt to consolidate the separate MAMA API endpoints
 * into a single JSON resource. The extension that Roots uses to communicate
 * with JSON endpoints (`roots-records`) seems to have a lot of horrible edge-case scenario bugs
 * where sometimes records don't evaluate in time or even at all, especially in layout
 * files or single view template files, and working
 * around these flaws has proven to be really hacky and horrible.
 */

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

    // locales
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

    // categories
    categories = categories.map(function(category) {
      // delete the version prop
      delete category._version;
      // find all articles that are featured in the category
      category.featured_pages = pages.filter(function(page) {
        return (page.featured_in_category) &&
               (page.primary_category === category.uuid) && 
               (page.language === category.language);
      }).sort(function(a, b) {
        return a.position - b.position;
      });
      // find all articles that belong to this category
      category.pages = pages.filter(function(page) {
        return (page.language === category.language) &&
               (page.primary_category === category.uuid);
      }).sort(function(a, b) {
        return a.position - b.position;
      });
      // we're done here
      return category;
    }).sort(function(a, b) {
      return a.position - b.position;
    });

    // pages
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
          if ((page2.language === page.language) && (linked_page === page2.uuid)) {
            linked_page = {
              uuid: page2.uuid,
              title: page2.title,
              description: page2.description,
              slug: page2.slug
            }
          }
        });
        return linked_page;
      });

      // obtain more information regarding the primary category
      categories.forEach(function(category) {
        if ((category.language === page.language) && (page.primary_category === category.uuid)) {
          page.primary_category = {
            uuid: category.uuid,
            title: category.title,
            slug: category.slug
          };
        }
      });
      // we're done here
      return page;
    });

    // create a record for categories that are featured in the navigation bar
    var navbar_features = categories.filter(function(category) {
      return category.featured_in_navbar === true;
    });

    // build a list of all recommended articles and the categories they belong to
    var recommended_pages = pages.filter(function(page) {
      return page.featured === true;
    }).sort(function(a, b) {
      return a.position - b.position;
    });

    var data = {
      locales: locales,
      categories: categories,
      pages: pages,
      navbar_features: navbar_features,
      recommended_pages: recommended_pages
    };

    var data2 = {
      categories: {},
      pages: {},
      navbar_features: {},
      recommended_pages: {}
    };

    Object.keys(data).forEach(function(key) {
      switch (key) {
        case 'categories':
        case 'pages':
        case 'navbar_features':
        case 'recommended_pages':
          locales.forEach(function(locale) {
            data2[key][locale.locale] = {
              collection: data[key].filter(function(item) {
                return item.language === locale.locale;
              })
            };
          });
          break;
        default:
          data2[key] = data[key];
      }
    });

    data = data2;

    node.call(fs.writeFile, './_data.json', JSON.stringify(data, null, 2), 'utf-8');

  })
  .catch(function(error) {
    console.error(error);
  })
  .done();
