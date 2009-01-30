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


namespace :i18n do
  namespace :populate do
    desc 'Populate locales and translations tables'
    task :all do
      Rake::Task['i18n:populate:locales'].invoke
    end

    desc 'Populate the locales table'
    task :locales => :environment do
      load_from_csv("locales")
    end
  end
end
