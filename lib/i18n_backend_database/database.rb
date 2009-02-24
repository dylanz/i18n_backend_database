require 'digest/md5'
require 'base64'

module I18n
  module Backend
    class Database
      INTERPOLATION_RESERVED_KEYS = %w(scope default)
      MATCH = /(\\\\)?\{\{([^\}]+)\}\}/

      attr_accessor :locale
      attr_accessor :cache_store

      def initialize(options = {})
        store = options.delete(:cache_store)
        @cache_store = store ? ActiveSupport::Cache.lookup_store(store) : Rails.cache
      end

      def locale=(code)
        @locale = Locale.find_by_code(code)
      end

      def cache_store=(store)
        @cache_store = ActiveSupport::Cache.lookup_store(store)
      end

      # Handles the lookup and addition of translations to the database
      #
      # On an initial translation, the locale is checked to determine if
      # this is the default locale.  If it is, we'll create a complete
      # translation record for this locale with both the key and value.
      #
      # If the current locale is checked, and it differs from the default
      # locale, we'll create a translation record with a nil value.  This
      # allows for the lookup of untranslated records in a given locale.
      def translate(locale, key, options = {})
        @locale = locale_in_context(locale)

        # create a composite key if scope provided
        original_key = key
        options[:scope] = [options[:scope]] unless options[:scope].is_a?(Array)
        key = "#{options[:scope].join('.')}.#{key}" if options[:scope] && key.is_a?(Symbol)
        count = (options[:count].nil? || options[:count] == 1) ? 1 : 0
        cache_key = Translation.ck(@locale, key, count)

        # pull out values for interpolation
        values = options.reject { |name, value| [:scope, :default].include?(name) }

        if @cache_store.exist?(cache_key)
          translation = @cache_store.read(cache_key)
          return interpolate(@locale.code, translation, values) if translation
        else
          translation =  @locale.translations.find_by_key_and_pluralization_index(Translation.hk(key), count)
          # what we are crossing our fingers for is that this will cache the fact that this key has NO db translation
          @cache_store.write(Translation.ck(@locale, key, count), nil) unless translation
        end

        if !translation && !@locale.default_locale?
          default_locale_cache_key = Translation.ck(Locale.default_locale, key, count)

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

        # Interpolates values into a given string.
        # 
        #   interpolate "file {{file}} opened by \\{{user}}", :file => 'test.txt', :user => 'Mr. X'  
        #   # => "file test.txt opened by {{user}}"
        # 
        # Note that you have to double escape the <tt>\\</tt> when you want to escape
        # the <tt>{{...}}</tt> key in a string (once for the string and once for the
        # interpolation).
        def interpolate(locale, string, values = {})
          return string unless string.is_a?(String)

          if string.respond_to?(:force_encoding)
            original_encoding = string.encoding
            string.force_encoding(Encoding::BINARY)
          end

          result = string.gsub(MATCH) do
            escaped, pattern, key = $1, $2, $2.to_sym

            if escaped
              pattern
            elsif INTERPOLATION_RESERVED_KEYS.include?(pattern)
              raise ReservedInterpolationKey.new(pattern, string)
            elsif !values.include?(key)
              raise MissingInterpolationArgument.new(pattern, string)
            else
              values[key].to_s
            end
          end

          result.force_encoding(original_encoding) if original_encoding
          result
        end

    end
  end
end
