module I18n
  class Locale < ActiveRecord::Base
    has_many :translations

    def self.available_locales
      all.map(&:code).map(&:to_sym)
    end
  end
end
