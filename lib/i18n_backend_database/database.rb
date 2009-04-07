require 'digest/md5'
require 'base64'

module I18n
  module Backend
    class Database
      INTERPOLATION_RESERVED_KEYS = %w(scope default)
      MATCH = /(\\\\)?\{\{([^\}]+)\}\}/

      attr_accessor :locale
      attr_accessor :cache_store
      attr_accessor :localize_text_tag

      def initialize(options = {})
        store = options.delete(:cache_store)
        text_tag = options.delete(:localize_text_tag)
        @cache_store = store ? ActiveSupport::Cache.lookup_store(store) : Rails.cache
        @localize_text_tag = text_tag ? text_tag : '^^'
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

        options[:scope] = [options[:scope]] unless options[:scope].is_a?(Array) || options[:scope].blank?
        key = "#{options[:scope].join('.')}.#{key}".to_sym if options[:scope] && key.is_a?(Symbol)
        count = options[:count]
        # pull out values for interpolation
        values = options.reject { |name, value| [:scope, :default].include?(name) }

        entry = lookup(@locale, key)
        cache_lookup = true unless entry.nil?

        # if no entry exists for the current locale and the current locale is not the default locale then lookup translations for the default locale for this key
        unless entry || @locale.default_locale?
          entry = use_and_copy_default_locale_translations_if_they_exist(@locale, key)
        end

        # if we have no entry and some defaults ... start looking them up
        unless key.is_a?(String) || entry || options[:default].blank?
          default = options[:default].is_a?(Array) ? options[:default].shift : options.delete(:default)
          return translate(@locale.code, default, options.dup)
        end

        # we check the database before creating a translation as we can have translations with nil values
        # if we still have no blasted translation just go and create one for the current locale!
        unless entry 
          pluralization_index = (options[:count].nil? || options[:count] == 1) ? 1 : 0
          translation =  @locale.translations.find_by_key_and_pluralization_index(Translation.hk(key), pluralization_index) ||
                         @locale.create_translation(key, key, pluralization_index)
          entry = translation.value_or_default
        end

        # write to cache unless we've already had a successful cache hit
        @cache_store.write(Translation.ck(@locale, key), entry) unless cache_lookup == true

        entry = pluralize(@locale, entry, count)
        entry = interpolate(@locale.code, entry, values)
        entry.is_a?(Array) ? entry.dup : entry # array's can get frozen with cache writes
      end

      # Acts the same as +strftime+, but returns a localized version of the 
      # formatted date string. Takes a key from the date/time formats 
      # translations as a format argument (<em>e.g.</em>, <tt>:short</tt> in <tt>:'date.formats'</tt>).        
      def localize(locale, object, format = :default)
        raise ArgumentError, "Object must be a Date, DateTime or Time object. #{object.inspect} given." unless object.respond_to?(:strftime)
        
        type = object.respond_to?(:sec) ? 'time' : 'date'
        format = translate(locale, "#{type}.formats.#{format.to_s}") unless format.to_s.index('%') # lookup keyed formats unless a custom format is passed

        format.gsub!(/%a/, translate(locale, :"date.abbr_day_names")[object.wday]) 
        format.gsub!(/%A/, translate(locale, :"date.day_names")[object.wday])
        format.gsub!(/%b/, translate(locale, :"date.abbr_month_names")[object.mon])
        format.gsub!(/%B/, translate(locale, :"date.month_names")[object.mon])
        format.gsub!(/%p/, translate(locale, :"time.#{object.hour < 12 ? :am : :pm}")) if object.respond_to? :hour
        
        object.strftime(format)
      end

      # Returns the text string with the text within the localize text tags translated.
      def localize_text(locale, text)
        text_tag    = Regexp.escape(localize_text_tag).to_s
        expression  = Regexp.new(text_tag + "(.*?)" + text_tag)
        tagged_text = text[expression, 1]
        while tagged_text do
          text = text.sub(expression, translate(locale, tagged_text))
          tagged_text = text[expression, 1]
        end
        return text
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

        # lookup key in cache and db, if the db is hit the value is cached
        def lookup(locale, key)
          cache_key = Translation.ck(locale, key)
          if @cache_store.exist?(cache_key) && value = @cache_store.read(cache_key)
            return value
          else
            translations = locale.translations.find_all_by_key(Translation.hk(key))
            case translations.size
            when 0
              value = nil
            when 1
              value = translations.first.value_or_default
            else
              value = translations.inject([]) do |values, t| 
                values[t.pluralization_index] = t.value_or_default
                values
              end
            end

            @cache_store.write(cache_key, (value.nil? ? nil : value))
            return value
          end
        end

        # looks up translations for the default locale, and if they exist untranslated records are created for the locale and the default locale values are returned 
        def use_and_copy_default_locale_translations_if_they_exist(locale, key)
          default_locale_entry = lookup(Locale.default_locale, key)
          return unless default_locale_entry

          if default_locale_entry.is_a?(Array)
            default_locale_entry.each_with_index do |entry, index|
              locale.create_translation(key, nil, index) if entry
            end
          else
            locale.create_translation(key, nil) 
          end

          return default_locale_entry
        end

        def pluralize(locale, entry, count)
          return entry unless entry.is_a?(Array) and count
          count = count == 1 ? 1 : 0
          entry.compact[count]
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
