module ShopInvader::Middlewares
  module Concerns
    module Sitemap
      module Algolia

        extend ActiveSupport::Concern

        included do

          alias_method :build_xml_without_algolia, :build_xml

          private

          def build_xml
            build_xml_without_algolia.gsub('</urlset>', algolia_records_to_xml + '</urlset>')
          end

        end

        private

        def algolia_records_to_xml
          algolia.find_all_products_and_categories.map do |record|
            algolia_record_to_xml(record)
          end.flatten.join.strip
        end

        def algolia_record_to_xml(record)
          <<-EOF
    <url>
      #{algolia_record_url(record, default_locale)}
      #{algolia_record_in_other_locales(record)}
    </url>
          EOF
        end

        def algolia_record_in_other_locales(record)
          locales.map do |locale|
            next if locale == default_locale
            algolia_record_url(record, locale)
          end.compact.flatten.join.strip
        end

        def algolia_record_url(record, locale)
          return nil if record[locale].nil?
          url = [base_url, locale == default_locale ? nil : locale, record[locale][:url]].compact.join('/')
          if locale == default_locale
            "<loc>#{url}</loc>"
          else
            "<xhtml:link rel=\"alternate\" hreflang=\"#{locale}\" href=\"#{url}\" />"
          end
        end

        def algolia
          services.algolia
        end

      end
    end
  end
end
