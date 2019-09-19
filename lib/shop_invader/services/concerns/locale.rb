module ShopInvader
  module Services
    module Concerns

      module LocaleMapping

        private

        def map_locale(locale)
          mapping = JSON.parse(@site.metafields.dig('_store', 'locale_mapping') || '{}')
          mapping[@locale.to_s] || ShopInvader::LOCALES[locale.to_s]
        end
      end
    end
  end
end
