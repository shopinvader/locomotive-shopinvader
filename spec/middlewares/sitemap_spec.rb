require 'spec_helper'

describe Locomotive::Steam::Middlewares::Sitemap do

  let(:site)            { instance_double('Site', locales: ['en', 'fr'], default_locale: 'en', metafields: {}, ) }
  let(:pages)           { [] }
  let(:page_repository) { instance_double('PageRepository', published: pages) }
  let(:records)         { [] }
  let(:algolia)         { instance_double('AlgoliaService', find_all_products_and_categories: records) }
  let(:app)             { ->(env) { [200, env, 'app'] }}
  let(:middleware)      { described_class.new(app) }
  let(:request)         { }
  before do
    allow_any_instance_of(described_class).to receive(:site).and_return(site)
    allow_any_instance_of(described_class).to receive(:base_url).and_return('http://localhost')
    allow_any_instance_of(described_class).to receive(:page_repository).and_return(page_repository)
    allow_any_instance_of(described_class).to receive(:algolia).and_return(algolia)
  end

  describe '#call' do

    subject { middleware.call(build_env) }

    describe 'no pages' do

      it 'renders a blank sitemap' do
        is_expected.to eq [200, { 'Cache-Control' => 'max-age=0, private, must-revalidate', 'Content-Type' => 'text/plain' }, ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n  <url>\n    <loc>http://localhost</loc>\n    <priority>1.0</priority>\n  </url>\n\n</urlset>\n"]]
      end

    end

    describe 'with algolia records' do

      let(:records) { [{"fr"=>{url: 'bose-mini-bluetooth-speaker-B3423-FR'},"en"=>{:name=>"Bose Mini Bluetooth Speaker", :url=>"bose-mini-bluetooth-speaker-B3423"}}, {"en"=>{:name=>"iPad Retina Display", :url=>"ipad-retina-display-A2323"}}, {"en"=>{:name=>"iPad Retina Display", :url=>"ipad-retina-display-A2323"}}, {"en"=>{:name=>"Ice Cream", :url=>"ice-cream-1"}}, {"en"=>{:name=>"Switch, 24 ports", :url=>"switch-24-ports-SW24"}}, {"en"=>{:name=>"Datacard", :url=>"datacard-DC"}}, {"en"=>{:name=>"Router R430", :url=>"router-r430-ROUT_430"}}, {"en"=>{:name=>"GrapWorks Software", :url=>"grapworks-software-GRAPs/w"}}, {"en"=>{:name=>"iPad Retina Display", :url=>"ipad-retina-display-A2323"}}, {"en"=>{:name=>"Zed+ Antivirus", :url=>"zed-antivirus-Zplus"}}, {"en"=>{:name=>"Office Suite", :url=>"office-suite-OSuite"}}, {"en"=>{:name=>"Windows Home Server 2011", :url=>"windows-home-server-2011-WServer"}}, {"en"=>{:name=>"Windows 7 Professional", :url=>"windows-7-professional-Win7"}}, {"en"=>{:name=>"Toner Cartridge", :url=>"toner-cartridge-TONER"}}, {"en"=>{:name=>"Ink Cartridge", :url=>"ink-cartridge-INK"}}, {"en"=>{:name=>"Printer, All-in-one", :url=>"printer-all-in-one-PRINT"}}, {"en"=>{:name=>"Blank DVD-RW", :url=>"blank-dvd-rw-DVD"}}, {"en"=>{:name=>"Blank CD", :url=>"blank-cd-CD"}}, {"en"=>{:name=>"Webcam", :url=>"webcam-WCAM"}}, {"en"=>{:name=>"PC Assemble SC234", :url=>"pc-assemble-sc234-PCSC234"}}, {"en"=>{:name=>"Headset USB", :url=>"headset-usb-HEAD-USB"}}, {"en"=>{:name=>"Headset standard", :url=>"headset-standard-HEAD"}}, {"en"=>{:name=>"Multimedia Speakers", :url=>"multimedia-speakers-MM-SPK"}}, {"en"=>{:name=>"Pen drive, SP-4", :url=>"pen-drive-sp-4-PD-SP4"}}, {"en"=>{:name=>"Pen drive, SP-2", :url=>"pen-drive-sp-2-PD-SP2"}}, {"en"=>{:name=>"External Hard disk", :url=>"external-hard-disk-EXT-HDD"}}, {"en"=>{:name=>"Laptop Customized", :url=>"laptop-customized-LAP-CUS"}}, {"en"=>{:name=>"Laptop S3450", :url=>"laptop-s3450-LAP-S3"}}, {"en"=>{:name=>"Laptop E5023", :url=>"laptop-e5023-LAP-E5"}}, {"en"=>{:name=>"Graphics Card", :url=>"graphics-card-CARD"}}, {"en"=>{:name=>"On Site Assistance", :url=>"on-site-assistance"}}, {"en"=>{:name=>"Processor AMD 8-Core", :url=>"processor-amd-8-core-CPUa8"}}, {"en"=>{:name=>"Processor Core i5 2.70 Ghz", :url=>"processor-core-i5-270-ghz-CPUi5"}}, {"en"=>{:name=>"Motherboard A20Z7", :url=>"motherboard-a20z7-MBa20"}}, {"en"=>{:name=>"Motherboard I9P57", :url=>"motherboard-i9p57-MBi9"}}, {"en"=>{:name=>"HDD on Demand", :url=>"hdd-on-demand-HDD-DEM"}}, {"en"=>{:name=>"HDD SH-2", :url=>"hdd-sh-2-HDD-SH2"}}, {"en"=>{:name=>"HDD SH-1", :url=>"hdd-sh-1-HDD-SH1"}}, {"en"=>{:name=>"Computer Case", :url=>"computer-case-C-Case"}}, {"en"=>{:name=>"RAM SR3", :url=>"ram-sr3-RAM-SR3"}}, {"en"=>{:name=>"RAM SR2", :url=>"ram-sr2-RAM-SR2"}}, {"en"=>{:name=>"On Site Monitoring", :url=>"on-site-monitoring"}}, {"en"=>{:name=>"RAM SR5", :url=>"ram-sr5-RAM-SR5"}}, {"en"=>{:name=>"Mouse, Wireless", :url=>"mouse-wireless-M-Wir"}}, {"en"=>{:name=>"iPod", :url=>"ipod-A6678"}}, {"en"=>{:name=>"iPod", :url=>"ipod-A6678"}}, {"en"=>{:name=>"Mouse, Optical", :url=>"mouse-optical-M-Opt"}}, {"en"=>{:name=>"Apple Wireless Keyboard", :url=>"apple-wireless-keyboard-AK789"}}, {"en"=>{:name=>"iMac", :url=>"imac-A1090"}}, {"en"=>{:name=>"Apple In-Ear Headphones", :url=>"apple-in-ear-headphones-A8767"}}, {"en"=>{:name=>"iPad Mini", :url=>"ipad-mini-A1232"}}, {"en"=>{:name=>"PC Assemble + Custom (PC on Demand) ", :url=>"pc-assemble-custom-pc-on-demand-B3424"}}, {"en"=>{:name=>"Service", :url=>"service"}}, {"en"=>{:name=>"Components", :url=>"all/saleable/components"}}, {"en"=>{:name=>"Accessories", :url=>"all/saleable/accessories"}}, {"en"=>{:name=>"External Devices", :url=>"all/saleable/external-devices"}}, {"en"=>{:name=>"Services", :url=>"all/saleable/services"}}, {"en"=>{:name=>"Computers", :url=>"all/saleable/computers"}}, {"en"=>{:name=>"Other Products", :url=>"all/other-products"}}, {"en"=>{:name=>"Internal", :url=>"all/internal"}}, {"en"=>{:name=>"Saleable", :url=>"all/saleable"}}, {"en"=>{:name=>"Apple Accessories", :url=>"apple-products/apple-accessories"}}, {"en"=>{:name=>"All Imac", :url=>"apple-products/all-imac"}}, {"en"=>{:name=>"All Ipod", :url=>"apple-products/all-ipod"}}, {"en"=>{:name=>"Ipad", :url=>"apple-products/ipad"}}, {"en"=>{:name=>"Apple Products", :url=>"apple-products"}}, {"en"=>{:name=>"Raw Materials", :url=>"all/other-products/raw-materials"}}, {"en"=>{:name=>"Software", :url=>"all/saleable/software"}}, {"en"=>{:name=>"All", :url=>"all"}}] }

      it 'renders a sitemap including all the records from Algolia' do
        expect(subject[0]).to eq 200
        expect(subject[1]).to eq({ 'Cache-Control' => 'max-age=0, private, must-revalidate', 'Content-Type' => 'text/plain' })
        expect(subject[2].first).to include("<url>\n      <loc>http://localhost/bose-mini-bluetooth-speaker-B3423</loc>\n      <xhtml:link rel=\"alternate\" hreflang=\"fr\" href=\"http://localhost/fr/bose-mini-bluetooth-speaker-B3423-FR\" />\n    </url>")
      end

    end

  end

  def build_env
    env_for('http://models.example.com', {
      'PATH_INFO' => '/sitemap.xml',
      'steam.site'            => site,
      'steam.page'            => nil,
      'steam.cookies'         => {},
    }).tap do |env|
      env['steam.request'] = Rack::Request.new(env)
    end
  end

end
