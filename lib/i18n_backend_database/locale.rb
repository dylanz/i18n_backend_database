module I18n
  class Locale < ActiveRecord::Base
    has_many :translations

    # find the translation, or create one if it doesn't exist
    def find_or_create_translation(key, options)
      conditions  = {:key => key, :pluralization_index => (options[:pluralization_index] || 1)}
      translation = self.translations.find(:first, :conditions => conditions)
      return translation if translation

      self.translations.create(conditions)
    end

    def self.available_locales
      all.map(&:code).map(&:to_sym)
    end
  end
end
