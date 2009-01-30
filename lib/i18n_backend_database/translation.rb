module I18n
  class Translation < ActiveRecord::Base
    belongs_to :locale

    # or, go through the dynamic finder, method_missing, path
    def self.find_or_create_key(locale, key, options)
      record = first(:first, :conditions => {
        :locale_id              => locale.id,
        :key                    => key,
        :pluralization_index    => (options[:pluralization_index] || 1)})
      unless record
        record = Translation.create({
          :locale_id            => locale.id,
          :key                  => key,
          :pluralization_index  => (options[:plurazilation_index] || 1)})
      end
      record
    end
  end
end
