class Hash
  # Returns a hash keyed by a method or an attribute
  def self.by_key(objs, method = nil, attr = nil)
    unless method.blank?
      method = method.to_sym
      return objs.inject({}){|r,e| r[e.send(method)] = e; r }
    end
    return objs.inject({}){|r,e| r[e[attr]] = e; r } unless attr.blank?
    return {}
  end
end
