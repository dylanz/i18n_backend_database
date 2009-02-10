require 'csv'

# csv files in the data/ directory are populated into tables equal to its file name.
def load_from_csv(file_name)
  begin
    csv = CSV.open(File.join(File.dirname(__FILE__), "../data", "#{file_name}.csv"), "r")
  rescue Errno::ENOENT
    # return if this file isn't present
  end

  connection = ActiveRecord::Base.connection
  if connection.adapter_name == 'postgresql'
    connection.execute "SELECT nextval('#{file_name}_id_seq')"
  end

  ActiveRecord::Base.silence do
    # ensure columns are properly formatted
    columns_clause = csv.shift.map { |column_name|
      connection.quote_column_name(column_name)
    }.join(', ')

    csv.each { |row|
      # ensure values are properly formatted
      values_clause = row.map { |v| connection.quote(v).gsub('\\n', "\n").gsub('\\r', "\r") }.join(', ')

      # insert the data
      sql = "INSERT INTO #{file_name} (#{columns_clause}) VALUES (#{values_clause})"
      connection.insert(sql)
    }
  end
end

def load_default_locales(path_to_file=nil)
  path_to_file ||= File.join(File.dirname(__FILE__), "../data", "locales.yml")
  data = YAML::load(IO.read(path_to_file))
  data.each do |code, y|
    Locale.create({:code => code, :name => y["name"]})
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
      translation = locale.translations.find_or_initialize_by_key(key)
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
    desc 'Populate locales and translations tables'
    task :all do
      Rake::Task['i18n:populate:locales'].invoke
    end

    desc 'Populate the locales table'
    task :locales => :environment do
      load_from_csv("locales")
    end
    
    desc 'Populate the locales and translations tables from a Locale YAML file.  Specify file using LOCALE_FILE=path_to_file'
    task :from_yaml => :environment do
      load_from_yml(ENV['LOCALE_FILE'])
    end

    desc 'Populate default locales'
    task :load_default_locales => :environment do
      load_default_locales(ENV['LOCALE_FILE'])
    end
  end
end
