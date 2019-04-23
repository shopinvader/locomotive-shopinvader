require File.dirname(__FILE__) + '/../integration_helper'

describe 'Connected to the search engine' do

  include Rack::Test::Methods

  def app
    run_server
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

  describe 'Rendering the sitemap' do
    it 'should include search engine content' do
      get 'sitemap.xml'
      expect(last_response.status).to eq 200
      path = File.expand_path('../../data/expected_sitemap.xml', __FILE__)
      data = File.read(path)
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
      expect(last_response.body).to eq "\n TV Media Stand Mid-Century Armchair (Red) Mid-Century Armchair (Yellow)\ntotal page: 2\ntotal entries: 4\n\n"
    end

  end
end
