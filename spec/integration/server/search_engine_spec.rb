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
    it 'get on "mid-century-armchair" return the product "Mid-Century Armchair (Red)"' do
        get 'mid-century-armchair'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Mid-Century Armchair (Red)\n"
    end

    it 'get on "fr/fauteuil-mid-century" return the french category "Fauteuil Mid-Century (Rouge)"' do
        get 'fr/fauteuil-mid-century'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Fauteuil Mid-Century (Rouge)\n"
    end
  end

end
