module I18n
  class Locale < ActiveRecord::Base
    validates_presence_of :code
    validates_uniqueness_of :code

    has_many :translations, :class_name => "I18n::Translation"

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
    
    def to_param
      self.code
    end
    
  end
end
