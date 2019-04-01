module ShopInvader::Middlewares
  module Concerns
    module Sitemap
      module Elasticsearch

        extend ActiveSupport::Concern

        included do

          alias_method :build_xml_without_elastic, :build_xml

          private

          def build_xml
            build_xml_without_elastic.gsub('</urlset>', elastic_records_to_xml + '</urlset>')
          end

        end

        private

        def elastic_records_to_xml
          elastic.find_all_products_and_categories.map do |record|
            elastic_record_to_xml(record)
          end.flatten.join.strip
        end

        def elastic_record_to_xml(record)
          <<-EOF
  <url>
    #{elastic_record_url(record, default_locale)}
    #{elastic_record_in_other_locales(record)}
  </url>
          EOF
        end

        def elastic_record_in_other_locales(record)
          locales.map do |locale|
            next if locale == default_locale
            elastic_record_url(record, locale)
          end.compact.flatten.join.strip
        end

        def elastic_record_url(record, locale)
          return nil if record[locale].nil?
          url = [base_url, locale == default_locale ? nil : locale, record[locale][:url]].compact.join('/')
          if locale == default_locale
            "<loc>#{url}</loc>"
          else
            "<xhtml:link rel=\"alternate\" hreflang=\"#{locale}\" href=\"#{url}\" />"
          end
        end

        def elastic
          services.elastic
        end

      end
    end
  end
end
