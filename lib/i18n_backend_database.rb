module I18n
  module Backend
    class Database
      attr_accessor :locale
      attr_accessor :cache_store

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
        cache_key = build_cache_key((tmp_locale || @locale), key, options)

        # check for key and return it if it exists
        value = @cache_store.read(cache_key)
        return value if value

        # find or create translation record
        locale_in_context = (tmp_locale || @locale)
        value = locale_in_context.find_or_create_translation(cache_key, options).value

        # NOTE: raw ok with non-memcache stores?
        @cache_store.write(cache_key, value, :raw => true)

        value || key
      end

      def available_locales
        Locale.available_locales
      end

      def reload!
        # get's called on initialization
        # let's not do anything yet
      end

      protected
        # locale:"key":pluralization_index
        def build_cache_key(locale, key, options)
          "#{locale.code}:#{key}:#{(options[:pluralization_index] || 1)}"
        end
    end
  end
end
