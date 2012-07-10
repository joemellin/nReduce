module ActsAsTaggableOn
  class Tag
    # Find tag(s) matching this string (split on commas)
    def self.named_like_any_from_string(str = '')
      return [] if str.blank?
      tag_search = str.downcase.split(',').map{|s| s.strip }.delete_if{|t| t.blank? }
      return [] if tag_search.blank?
      ActsAsTaggableOn::Tag.named_any(tag_search)
    end
  end
end