require 'cgi'
require 'net/http'
require 'json'

class GoogleLanguage

  # Thanks http://ruby.geraldbauer.ca/google-translation-api.html
  def self.translate( text, to, from='en' )

    base = 'http://ajax.googleapis.com/ajax/services/language/translate' 

    # assemble query params
    params = {
      :langpair => "#{from}|#{to}", 
      :q => text,
      :v => 1.0  
    }

    query = params.map{ |k,v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')

    # send get request
    response = Net::HTTP.get_response( URI.parse( "#{base}?#{query}" ) )

    json = JSON.parse( response.body )

      if json['responseStatus'] == 200
        json['responseData']['translatedText']
      else
        raise StandardError, response['responseDetails']
      end
  end

end