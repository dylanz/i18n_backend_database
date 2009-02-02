map.resources :locales, :name_prefix => 'i18n_' do |locales|
  locales.resources :translations
end
