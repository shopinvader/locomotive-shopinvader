# ShopInvader

[![Build Status](https://travis-ci.org/akretion/locomotive_shopinvader.svg?branch=master)](https://travis-ci.org/akretion/locomotive_shopinvader) [![Code Climate](https://codeclimate.com/github/akretion/locomotive_shopinvader/badges/gpa.svg)](https://codeclimate.com/github/akretion/locomotive_shopinvader)[![Test Coverage](https://api.codeclimate.com/v1/badges/2aa860bd2b735c93ebd8/test_coverage)](https://codeclimate.com/github/akretion/locomotive_shopinvader/test_coverage)

## Installation

### Wagon

Add this line to your Wagon site's Gemfile:

```ruby
group :misc do
  gem 'shop_invader', path: '<local version of the ShopInvader gem>'
end
```

**Very important**. Use the very last commits of both Wagon and Steam.

And then execute:

    $ bundle

Modify the `config/site.yml` to include Algolia's settings:

```
metafields:
  algolia:
    application_id: '<YOUR ALGOLIA APPLICATION ID>'
    api_key: '<YOUR ALGOLIA API KEY>'
    public_role: >
      [
        { "name": "category", "index": "category", "template_handle": "category" },
        { "name": "product", "index": "public_tax_inc", "template_handle": "product" }
      ]

```

**Notes:**

- your customer content type should have a role attribute (possible values: public, pro, ...etc).
- the template_handle is not required. If blank, the name attribute will be used as the template handle.
- put the product/category/... templates in the `app/views/pages/templates` folder.

### Locomotive Engine (Rails app)

Add this line to your Rails app's Gemfile:

```ruby
gem 'shop_invader', path: '<local version of the ShopInvader gem>'
```

Inside your `config/application.rb` file, add the following lines.

```ruby
module MyApp
  class Application < Rails::Application

    ...

    # Steam
    initializer 'station.steam', after: 'steam' do |app|
      Locomotive::Steam.configure do |config|
        ShopInvader.setup
      end
    end

    ...
  end
end
```

## Usage

### Templatized page

If you request the http://mysite.com/<URL_KEY> page and no Locomotive page matches this url, then the gem will look for Algolia resources based on their `url_key` and `redirect_url_key` properties.

- if Algolia returns a category, a `category` liquid global variable will be available in the liquid template.
- if Algolia returns a product, a `product` liquid global variable will be available in the liquid template.

### Liquid

#### List all the categories

```liquid
{% for category in store.category %}
  <h2>{{ category.name }}</h2>
{% endfor %}
```

#### List the products and filter them

```liquid
{% with_scope rating_value.gt: 4.7 %}
  {% for product in store.product %}
    <h2>{{ product.name }}</h2>
  {% endfor %}
{% endwith_scope %}
```

#### Paginate a list of products belonging to a category

```liquid
{% with_scope categories_ids: [category.objectID] %}
  {% paginate store.product by 3 %}
    {% for product in paginate.collection %}
      <h2>{{ product.name }}</h2>
      <img src="{{ product.images.first.medium }}" />
      {{ product.short_description }}
    {% endfor %}
  {% endpaginate %}
{% endwith_scope %}
```

## TODO

- [ ] we should review the way to build the "with_scope" filter current syntax in 'categories': {'id': 5} maybe something like 'categories.id': 5 will be more explicit
- [ ] use a pool of connexion for the connecting to Odoo
- [ ] in product.variants put all of the variant included himself
- [ ] review API path (with thibault, maybe we should use invader?)
- [ ] add integration test
- [ ] have 100 % of coverage


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/did/shop_invader.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

