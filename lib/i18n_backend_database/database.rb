require 'digest/md5'
require 'base64'

module I18n
  module Backend
    class Database
      attr_accessor :locale
      attr_accessor :cache_store

      def initialize(options = {})
        store   = options.delete(:cache_store)
        @cache_store = store ? ActiveSupport::Cache.lookup_store(store) : Rails.cache
      end

      def locale=(code)
        @locale = Locale.find_by_code(code)
      end

      def cache_store=(store)
        @cache_store = ActiveSupport::Cache.lookup_store(store)
      end

      def translate(locale, key, options = {})
        @locale   = locale_in_context(locale)
        cache_key = build_cache_key(@locale, generate_hash_key(key))

        # check for key and return it if it exists
        value = @cache_store.read(cache_key)
        return value if value

        # find or create translation record, and write to the store
        # NOTE: raw ok with non-memcache stores?
        value = @locale.find_or_create_translation(generate_hash_key(key), key).value
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
        # keep a local copy of the locale in context for use within the translation
        # routine, and also accept an arbitrary locale for one time locale lookups
        def locale_in_context(tmp_locale=nil)
          if @locale && tmp_locale
            # the passed locale is different than the cache
            unless @locale.code == tmp_locale.to_s
              Locale.find_by_code(tmp_locale.to_s)
            else
              @locale
            end
          elsif @locale
            # synch cache with I18n.locale
            unless @locale.code == I18n.locale.to_s
              Locale.find_by_code(I18n.locale.to_s)
            else
              @locale
            end
          else
            Locale.find_by_code(I18n.locale.to_s)
          end
        end

        # locale:"key"
        def build_cache_key(locale, key)
          "#{locale.code}:#{key}"
        end

        def generate_hash_key(key)
          Base64.encode64(Digest::MD5.hexdigest(key))
        end
    end
  end
end
