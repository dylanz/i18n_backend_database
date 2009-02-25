map.resources :locales, :has_many => :translations
map.untranslated '/untranslated', :controller => 'translations', :action => 'untranslated'
map.untranslated_assets '/untranslated_assets', :controller => 'translations', :action => 'untranslated_assets'