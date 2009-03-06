class I18nUtil

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
            create_translation(locale, "#{key}.#{index}", pluralization_index, v.to_s) unless v.nil?
          end
        else
          create_translation(locale, key, pluralization_index, value)
        end

      end
    end
  end

  def self.create_translation(locale, key, pluralization_index, value)
    translation = locale.translations.find_by_key_and_pluralization_index(Translation.hk(key), pluralization_index) # find existing record by hash key
    translation = locale.translations.build(:key =>key, :pluralization_index => pluralization_index) unless translation # or build new one with raw key
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

  def self.seed_application_translations
    translated_objects.each do |object|
      begin
        I18n.t(object) # default locale first
        locales =  Locale.available_locales
        locales.delete(I18n.default_locale)
        # translate for other locales
        locales.each do |locale|
          I18n.t(object, :locale => locale)
        end
      rescue
        # ignore errors
      end
    end
  end

  def self.translated_objects(dir='app/views')
    assets = []
    Dir.glob("#{dir}/*").each do |item|
      if File.directory?(item)
        assets += translated_objects(item)
      else
        File.readlines(item).each do |l|
          translated_object = l[/I18n.t\('(.*?)'\)/, 1] || l[/I18n.t\("(.*?)"\)/, 1]
          assets << translated_object if translated_object
        end
      end
    end
    assets
  end

end