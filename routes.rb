map.resources :locales, :has_many => :translations
map.translations '/translations', :controller => 'translations', :action => 'translations'
map.asset_translations '/asset_translations', :controller => 'translations', :action => 'asset_translations'