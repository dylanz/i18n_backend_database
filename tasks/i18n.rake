def load_default_locales(path_to_file=nil)
  path_to_file ||= File.join(File.dirname(__FILE__), "../data", "locales.yml")
  data = YAML::load(IO.read(path_to_file))
  data.each do |code, y|
    Locale.create({:code => code, :name => y["name"]})
  end
end

def load_from_rails
  I18n.load_path.each do |file|
    load_from_yml file
  end
end

def load_from_yml(file_name)
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

      translation = locale.translations.find_or_initialize_by_key_and_pluralization_index(key, pluralization_index)
      translation.value = value
      translation.save!
    end
  end
end

def extract_i18n_keys(hash, parent_keys = [])
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

namespace :i18n do
  desc 'Clear cache'
  task :clear_cache => :environment do
    I18n.backend.cache_store.clear
  end

  namespace :populate do
    desc 'Populate the locales and translations tables from all Rails Locale YAML files.'
    task :from_rails => :environment do
      load_from_rails
    end

    desc 'Populate default locales'
    task :load_default_locales => :environment do
      load_default_locales(ENV['LOCALE_FILE'])
    end
  end
end
