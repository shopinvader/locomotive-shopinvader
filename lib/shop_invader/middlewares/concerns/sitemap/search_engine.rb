module ShopInvader::Middlewares
  module Concerns
    module Sitemap
      module SearchEngine

        extend ActiveSupport::Concern

        included do

          alias_method :build_xml_without_search_engine, :build_xml

          private

          def build_xml
            build_xml_without_search_engine.gsub('</urlset>', search_engine_records_to_xml + '</urlset>')
          end

        end

        private

        def search_engine_records_to_xml
          search_engine.find_all_products_and_categories.map do |record|
            search_engine_record_to_xml(record)
          end.flatten.join.strip
        end

        def search_engine_record_to_xml(record)
          <<-EOF
    <url>
      #{search_engine_record_url(record, default_locale)}
      #{search_engine_record_in_other_locales(record)}
    </url>
          EOF
        end

        def search_engine_record_in_other_locales(record)
          locales.map do |locale|
            next if locale == default_locale
            search_engine_record_url(record, locale)
          end.compact.flatten.join.strip
        end

        def search_engine_record_url(record, locale)
          return nil if record[locale].nil?
          url = [base_url, locale == default_locale ? nil : locale, record[locale][:url]].compact.join('/')
          if locale == default_locale
            "<loc>#{url}</loc>"
          else
            "<xhtml:link rel=\"alternate\" hreflang=\"#{locale}\" href=\"#{url}\" />"
          end
        end

        def search_engine
          services.search_engine
        end

      end
    end
  end
end
