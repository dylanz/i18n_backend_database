class I18nBackendDatabaseGenerator < Rails::Generator::Base
  def manifest
    record { |m|
      m.migration_template "migrate/create_i18n_tables.rb", "db/migrate",
        :migration_file_name => "create_i18n_tables"
    }
  end
end
