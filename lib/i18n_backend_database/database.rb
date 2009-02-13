require 'digest/md5'
require 'base64'

module I18n
  module Backend
    class Database < I18n::Backend::Simple
      attr_accessor :locale
      attr_accessor :cache_store

      def initialize(options = {})
        init_translations
        store   = options.delete(:cache_store)
        @cache_store = store ? ActiveSupport::Cache.lookup_store(store) : Rails.cache
      end

      def locale=(code)
        @locale = Locale.find_by_code(code)
      end

      def cache_store=(store)
        @cache_store = ActiveSupport::Cache.lookup_store(store)
      end

      # handles the lookup and addition of translations to the database
      #
      # on an initial translation, the locale is checked to determine if
      # this is the default locale.  if it is, we'll create a complete
      # transaction record for this locale with both the key and value.
      #
      # if the current locale is checked, and it differs from the default
      # locale, we'll create a transaction record with a nil value.  this
      # allows for the lookup of untranslated records in a given locale.
      #
      # on hits, we simply return the stored value.
      # Rails.cache -> Database -> I18n.load_path
      #
      # on misses, we update the cache and database, and return the key:
      # Rails.cache -> Database -> I18n.load_path -> Database -> Rails.cache
      def translate(locale, key, options = {})
        @locale = locale_in_context(locale)

        # create a composite key if scope provided
        original_key = key
        key = "#{options[:scope].join('.')}.#{key}" if options[:scope] && key.is_a?(Symbol)
        count = (options[:count].nil? || options[:count] == 1) ? 1 : 0
        cache_key = build_cache_key(@locale, key, count)

        # pull out values for interpolation
        values = options.reject { |name, value| [:scope, :default].include?(name) }

        if @cache_store.exist?(cache_key)
          translation = @cache_store.read(cache_key)
          return interpolate(@locale.code, translation, values) if translation
        else
          translation =  @locale.translations.find_by_key_and_pluralization_index(Translation.hk(key), count)
          # what we are crossing our fingers for is that this will cache the fact that this key has NO db translation
          @cache_store.write(build_cache_key(@locale, key, count), nil) unless translation
        end


        if !translation && !@locale.default_locale?

          default_locale_cache_key = build_cache_key(Locale.default_locale, key, count)

          if @cache_store.exist?(default_locale_cache_key)
            default_locale_translation = @cache_store.read(default_locale_cache_key)
          else
            default_locale_translation = Locale.default_locale.translations.find_by_key_and_pluralization_index(Translation.hk(key), count)
            @cache_store.write(default_locale_cache_key, (default_locale_translation.nil? ? nil : default_locale_translation.value))
          end
          
          translation = @locale.create_translation(key, key, count) if default_locale_translation
        end

        # if we have no translation and some defaults ... start looking them up
        unless original_key.is_a?(String) || translation || options[:default].blank?
          default = options[:default].is_a?(Array) ? options[:default].shift : options.delete(:default)
          return translate(@locale.code, default, options.dup)
        end

        # if we still have no blasted translation just go and create one for the current locale!
        translation = @locale.create_translation(key, key, count) unless translation


        value = translation.value_or_default(key)
        @cache_store.write(cache_key, value)

        value = interpolate(@locale.code, value, values)
        value
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
        def locale_in_context(locale)
          return @locale if @locale && @locale.code == locale.to_s
          #Locale.find_by_code(locale.to_s) rescue nil && (raise InvalidLocale.new(locale))
          locale = Locale.find_by_code(locale.to_s)
          raise InvalidLocale.new(locale) unless locale
          locale
        end

        # locale:"key":pluralization_index
        def build_cache_key(locale, key, pluralization_index)
          "#{locale.code}:#{Translation.hk(key)}:#{pluralization_index}"
        end

        def internal_lookup?(key, default)
          key.is_a?(Symbol) && default.is_a?(Array) && default.all? {|a| a.is_a?(Symbol)}
        end

        # check default i18n load paths and return value if it exists
        def value_from_lookup(args = {})
          value = lookup(args[:locale], args[:original_key], args[:scope])
          value = value[:other] if value.is_a?(Hash)
          value = default(args[:locale], args[:default], args[:options]) if value.nil?
          return value
        end
    end
  end
end
