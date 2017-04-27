require 'spec_helper'

RSpec.describe 'Patches for Steam' do

  describe Locomotive::Steam::Models::Pager do

    let(:collection) { nil }
    let(:pager) { described_class.new(collection, 1, 20) }

    context 'the collection is from Algolia' do

      let(:collection) { instance_double('AlgoliaCollectionDrop') }

      it 'calls its paginate collection' do
        expect(collection).to receive(:paginate).with(1, 20).and_return(size: 0, data: [])
        expect(pager).not_to be_nil
      end

    end

    context 'the collection is from a content type drop' do

      let(:collection) { instance_double('ContentEntriesDrop', count: 5) }

      it 'calls its slice collection' do
        expect(collection).to receive(:slice).with(0, 6).and_return([])
        expect(pager).not_to be_nil
      end

    end

  end

end
