class I18nUtil

  # Create tanslation records from the YAML file.  Will create the required locales if they do not exist.
  def self.load_from_yml(file_name)
    data = YAML::load(IO.read(file_name))
    data.each do |code, translations| 
      locale = Locale.find_or_create_by_code(code)
      backend = I18n::Backend::Simple.new
      keys = extract_i18n_keys(translations)
      keys.each do |key|
        value = backend.send(:lookup, code, key)

        pluralization_index = 1

        if key.ends_with?('.one')
          key.gsub!('.one', '')
        end

        if key.ends_with?('.other')
          key.gsub!('.other', '')
          pluralization_index = 0
        end

        if value.is_a?(Array)
          value.each_with_index do |v, index|
            create_translation(locale, "#{key}", index, v) unless v.nil?
          end
        else
          create_translation(locale, key, pluralization_index, value)
        end

      end
    end
  end

  # Finds or creates a translation record and updates the value
  def self.create_translation(locale, key, pluralization_index, value)
    translation = locale.translations.find_by_key_and_pluralization_index(Translation.hk(key), pluralization_index) # find existing record by hash key
    unless translation # or build new one with raw key
      translation = locale.translations.build(:key =>key, :pluralization_index => pluralization_index)
      puts "from yaml create translation for #{locale.code} : #{key} : #{pluralization_index}" unless RAILS_ENV['test']
    end
    translation.value = value
    translation.save!
  end

  def self.extract_i18n_keys(hash, parent_keys = [])
    hash.inject([]) do |keys, (key, value)|
      full_key = parent_keys + [key]
      if value.is_a?(Hash)
        # Nested hash
        keys += extract_i18n_keys(value, full_key)
      elsif value.present?
        # String leaf node
        keys << full_key.join(".")
      end
      keys
    end
  end

  # Create translation records for all existing locales from translation calls with the application.  Ignores errors from tranlations that require objects.
  def self.seed_application_translations(dir='app')
    translated_objects(dir).each do |object|
      interpolation_arguments= object.scan(/\{\{(.*?)\}\}/).flatten
      object = object[/'(.*?)'/, 1] || object[/"(.*?)"/, 1]
      options = {}
      interpolation_arguments.each { |arg|  options[arg.to_sym] = nil }
      next if object.nil?

      puts "translating for #{object} with options #{options.inspect}" unless RAILS_ENV['test']        
      I18n.t(object, options) # default locale first
      locales =  Locale.available_locales
      locales.delete(I18n.default_locale)
      # translate for other locales
      locales.each do |locale|
        I18n.t(object, options.merge(:locale => locale))
      end

    end
  end

  def self.translated_objects(dir='app')
    assets = []
    Dir.glob("#{dir}/*").each do |item|
      if File.directory?(item)
        assets += translated_objects(item) unless item.ends_with?('i18n_backend_database') # ignore self
      else
        File.readlines(item).each do |l|
          assets += l.scan(/I18n.t\((.*?)\)/).flatten
        end
      end
    end
    assets.uniq
  end

  # Populate translation records from the default locale to other locales if no record exists.
  def self.synchronize_translations
    non_default_locales = Locale.non_defaults
    Locale.default_locale.translations.each do |t|
      non_default_locales.each do |locale|
        unless locale.translations.exists?(:key => t.key, :pluralization_index => t.pluralization_index)
          value = t.value =~ /^---(.*)\n/ ? t.value : nil # well will copy across YAML, like symbols
          locale.translations.create!(:key => t.raw_key, :value => value, :pluralization_index => t.pluralization_index)
          puts "synchronizing has created translation for #{locale.code} : #{t.raw_key} : #{t.pluralization_index}" unless RAILS_ENV['test']
        end
      end
    end
  end

  def self.google_translate
    Locale.non_defaults.each do |locale|
      locale.translations.untranslated.each do |translation|
        default_locale_value = translation.default_locale_value
        unless needs_human_eyes?(default_locale_value)
          interpolation_arguments= default_locale_value.scan(/\{\{(.*?)\}\}/).flatten

          if interpolation_arguments.empty?
            translation.value = GoogleLanguage.translate(default_locale_value, locale.code, Locale.default_locale.code)
            translation.save!
          else
            placeholder_value = 990 # at least in :es it seems to leave a 3 digit number in the postion on the string
            placeholders = {}

            # replace {{interpolation_arguments}} with a numeric place holder
            interpolation_arguments.each do |interpolation_argument|
              default_locale_value.gsub!("{{#{interpolation_argument}}}", "#{placeholder_value}")
              placeholders[placeholder_value] = interpolation_argument
              placeholder_value += 1
            end

            # translate string
            translated_value = GoogleLanguage.translate(default_locale_value, locale.code, Locale.default_locale.code)

            # replace numeric place holders with {{interpolation_arguments}} 
            placeholders.each {|placeholder_value,interpolation_argument| translated_value.gsub!("#{placeholder_value}", "{{#{interpolation_argument}}}") }
            translation.value = translated_value
            translation.save!
          end
        end
      end
    end
  end

  def self.needs_human_eyes?(value)
    return true if value.index('%')         # date formats
    return true if value =~ /^---(.*)\n/    # YAML
  end
end