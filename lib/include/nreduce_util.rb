class NreduceUtil
  def self.cleanup_phone_number(number)
    number.to_s.strip.gsub(%r{\D}, "").gsub(%r{^\+1}, "").gsub(%r{^1}, "")
  end

  def self.friendly_token(length = 15)
    SecureRandom.base64(length).tr('+/=', 'xyz')
  end

  def self.parse_twitter_handles(twitter_text)
    items = []

    twitter_text.to_s.split("\n").each do |line|
      line.split(",").each do |segment|
        segment.split(" ").each do |item|
          items << item
        end
      end
    end

    # clean up input and remove invalid entries
    items = items.map{|item| item.to_s.strip.downcase}.select{|item| item.present?}.uniq

    items = items.map{|item| "@"+item.to_s.gsub("@", "")}


    items
  end
end