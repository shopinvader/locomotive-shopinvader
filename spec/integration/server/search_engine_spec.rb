require File.dirname(__FILE__) + '/../integration_helper'

describe 'Connected to the search engine' do

  include Rack::Test::Methods

  def app
    run_server
  end

  ['elastic', 'algolia'].each do | backend |
    describe "# Testing Backend #{backend.titleize}" do

      before do
        if backend == 'algolia'
          allow_any_instance_of(ShopInvader::ElasticService).to receive(:is_configured?).and_return(false)
        end
      end

      describe 'testing rendering a category page' do
        it 'get on "furniture/living-room" return the category "living-room"' do
            get 'furniture/living-room'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Living room\n"
        end

        it 'get on "fr/meuble/salon" return the french category "salon"' do
            get 'fr/meuble/salon'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Salon\n"
        end
      end

      describe 'testing rendering a product page with variant' do
        it 'get on "mid-century-armchair" return the product "Mid-Century Armchair (Red) and with the variant"' do
            get 'mid-century-armchair'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Mid-Century Armchair (Red) Mid-Century Armchair (Blue) Mid-Century Armchair (Yellow)\n"
        end

        it 'get on "fr/fauteuil-mid-century" return the french category "Fauteuil Mid-Century (Rouge) with the variant"' do
          get 'fr/fauteuil-mid-century'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Fauteuil Mid-Century (Rouge) Fauteuil Mid-Century (Bleu) Fauteuil Mid-Century (Jaune)\n"
        end
      end

      describe 'testing a redirection on product page' do
        it 'get on "old-url-tv-media-stand" return the product 301"' do
          get 'old-url-tv-media-stand'
          expect(last_response.status).to eq 301
          expect(last_response.location).to eq "/tv-media-stand"
        end

        it 'get on "fr/ancienne-url-meuble-tv" return a 301 on the right french product"' do
          get 'fr/ancienne-url-meuble-tv'
          expect(last_response.status).to eq 301
          expect(last_response.location).to eq "/fr/meuble-tv"
        end
      end


      describe 'Rendering the sitemap' do
        it 'should include search engine content' do
          get 'sitemap.xml'
          expect(last_response.status).to eq 200
          path = File.expand_path('../../data/expected_sitemap.xml', __FILE__)
          # uncomment this to regenerate the expected_sitemap
          # check the new generated file before commit
          #File.open(path, 'w') do | file |
          #  file.write(last_response.body)
          #end
          data = File.read(path)
          # we hack the date
          data.sub!("<lastmod>2019-05-27</lastmod>", "<lastmod>#{Date.today.to_s}</lastmod>")
          expect(last_response.body).to eq data
        end
      end

      describe 'Rendering the drop' do

        it 'store.categories should list all categories' do
          get 'search-engine/store_categories'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq " Furniture Living room Bathroom\n"
        end

        it 'store.categories with scope level 0 should list one category' do
          get 'search-engine/store_categories_with_level_0'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq " Furniture\n"
        end

        it 'store.products with paginate do the pagination' do
          get 'search-engine/store_products_with_paginate'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "\nsize : 3\ntotal page: 2\ntotal entries: 5\n\n"
        end

        it 'store.products with scope on categories filter and main product should return 2 products' do
          get 'search-engine/store_products_with_scope_multi_level'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "\n\n  TV Media Stand\n\n  Mid-Century Armchair (Red)\n\n\n"
        end

        it 'store.products with scope on price should return 3 products' do
          get 'search-engine/store_products_with_scope_lt_gt'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "\n\n  Mid-Century Armchair (Red)\n\n  Mid-Century Armchair (Blue)\n\n  Mid-Century Armchair (Yellow)\n\n\n"
        end

        it 'store.products with scope with not equal filter should return 2 products' do
          get 'search-engine/store_products_with_scope_ne'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "\n\n  TV Media Stand\n\n  Laundry basket\n\n\n"
        end

        it 'store.products with scope with not in filter should return 1 products' do
          get 'search-engine/store_products_with_scope_nin'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "\n\n  Laundry basket\n\n\n"
        end

        it 'store.products with scope with in filter should return 2 products' do
          get 'search-engine/store_products_with_scope_in'
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "\n\n  TV Media Stand\n\n  Mid-Century Armchair (Red)\n\n  Mid-Century Armchair (Blue)\n\n  Mid-Century Armchair (Yellow)\n\n\n"
        end

      end
    end

  end

  describe "# Testing No Backend" do

    before do
      allow_any_instance_of(ShopInvader::ElasticService).to receive(:is_configured?).and_return(false)
      allow_any_instance_of(ShopInvader::AlgoliaService).to receive(:is_configured?).and_return(false)
    end

    it 'get page that do not exist should return a 404' do
      get 'missing-page'
      expect(last_response.status).to eq 404
    end

  end
end
