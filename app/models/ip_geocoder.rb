class IpGeocoder
  # requires 'geoip' gem
  @@geo_ip_db = nil

  def self.geocoder
    unless @@geo_ip_db
      database = File.join(Rails.root, 'db', 'GeoLiteCity.dat')
      if File.exists?(database)
        @@geo_ip_db = GeoIP.new(database)
      else
        raise "IP database doesn't exist - download from: http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz and place in /db/"
      end
    end
    @@geo_ip_db
  end

   # Returns hash of IP location
   # {:lat => Float, :lng => Float, :name => String, :country => 2 digit String }
  def self.geocode_ip(ip)
    res = self.geocoder.city(ip)
    if res.blank?
      {}
    else
      {:lat => res.latitude, :lng => res.longitude, :name => [res.city_name, res.country_name].delete_if{|i| i.blank? }.join(', '), :country => res.country_code2}
    end
  end
end