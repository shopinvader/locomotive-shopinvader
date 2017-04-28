# ShopInvader

## Installation

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

- [x] redirect 301 (redirect_url_key)
- [] attach variants to a product (same url_key)
- [] different routes to display a product or a category
- [] liquid helper to build the path to a product or a category
- [] ERP proxy
- [] ERP liquid tags/drops/filters
- [] explain in the README how to set up the different indices in Algolia (Sebastien)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/did/shop_invader.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

