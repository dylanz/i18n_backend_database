module I18n 
  module BackendDatabase 
    module Routing 
      # Loads the set of routes from within a plugin and 
      # evaluates them at this point within an application’s 
      # main routes.rb file. 
      def from_plugin(name) 
        map = self # to make 'map' available within the plugin route file
        plugin_root = File.join(RAILS_ROOT, 'vendor', 'plugins') 
        routes_path = File.join(plugin_root, name.to_s, 'routes.rb') 
        eval(IO.read(routes_path), binding, routes_path) if File.file?(routes_path)
      end
    end 
  end 
end 
