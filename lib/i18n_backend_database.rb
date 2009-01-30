require 'i18n_backend_database/translation'
require 'i18n_backend_database/locale'

module I18n
  module Backend
    class Database
      def initialize(options = {})
        store   = options.delete(:cache_store)
        @cache_store = store ? ActiveSupport::Cache.lookup_store(store) : Rails.cache
        @locale = Locale.find_by_code(I18n.locale.to_s)
      end

      def cache_store=(store)
        @cache_store = ActiveSupport::Cache.lookup_store(store)
      end

      def translate(locale, key, options = {})
        # allow for arbitrary locale lookups.  use the cached locale otherwise.
        tmp_locale = Locale.find_by_code(locale.to_s) unless (@locale.code == locale)
        key = build_cache_key((tmp_locale || @locale), key, options)

        # check for key and return it if it exists
        value = @cache_store.read(key)
        return value if value

        # find or create translation record
        value = Translation.find_or_create_key((tmp_locale || @locale), key, options).value
        @cache_store.write(key, value, :raw => true) # FIXME: raw with non-memcache stores?

        value
      end

      def available_locales
        Locale.available_locales
      end

      protected
        # locale:"key":pluralization_index
        def build_cache_key(locale, key, options)
          "#{locale.code}:#{key}:#{(options[:pluralization_index] || 1)}"
        end
    end
  end
end
