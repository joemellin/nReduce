class String
  # For normalizing strings used in urls
  def to_url
    return nil if self.blank?
    self.gsub(/\s+/, '-').gsub(/[^\w^\-]+/, '').downcase
  end

  def possessive
    self + case self[-1,1]#1.8.7 style
    when 's' then "'"
    else "'s"
    end
  end
end