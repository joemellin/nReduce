# Create default user

unless 1 == 2 # User.where(:email => 'josh@nreduce.com').count > 0
  u = User.new(:name => 'Josh', :email => 'josh@nreduce.com', :password => 'bHAxMBr8', :password_confirmation => 'bHAxMBr8')
  u.admin = true
  u.save
end

# Seed from exported yaml files on old site

file = File.open("#{Rails.root}/lib/data/models.json", "rb"); false
contents = file.read; false
data = JSON.parse(contents).symbolize_keys; false

unless data.blank?
  auth_by_id = data[:authentication].inject({}){|res, e| res[e['id'].to_sym] = e.symbolize_keys unless e.blank?; res }
  failed = {}
  failed[:user] = []
  data[:authentication].each do |u|
    next if u.blank?
    u.symbolize_keys!
    user = User.new

    # Use 'send' to call the attributes= method on the object and ignore attr_accesible limitations
    u.reject{|k, v| [:authentication_id, :id, :provider, :uid, :token, :secret].include?(k) }.each do |k, v|
      user.send("#{k}=".to_sym, v)
    end

    user.email = "#{u[:twitter]}@users.nreduce.com" if user.email.blank?

    user.authentications.build(:uid => u[:uid], :provider => u[:provider], :token => u[:token], :secret => u[:secret])

    puts u.inspect if u[:id].blank?

    # Save the object
    if user.save!(:validate => false)
      auth_by_id[u[:id].to_sym][:user_id] = user.id
    else
      failed[:user].push(u)
    end
  end

  failed[:meeting] = []
  data[:location].each do |l|
    next if l.blank?
    l.symbolize_keys!
    meeting = Meeting.new
    unless l[:organizer_authentication_ids].blank?
      org = auth_by_id[l[:organizer_authentication_ids].first.to_sym]
      meeting.organizer_id = org[:user_id] if !org.blank?
    end
    l.reject{|k, v| k == :organizer_authentication_ids }.each do |k, v|
      meeting.send("#{k}=".to_sym, v)
    end
    failed[:meeting].push(l) unless meeting.save!
  end

  old_startup_ids = {}
  failed[:startup] = []
  data[:startup].each do |s|
    next if s.blank?
    s.symbolize_keys!
    startup = Startup.new
    unless s[:main_contact_authentication_id].blank?
      auth = auth_by_id[s[:main_contact_authentication_id].to_sym]
      startup.main_contact_id = auth[:user_id] if auth and auth[:user_id]
    end
    team_members_authentication_ids = s[:team_members_authentication_ids]
    old_startup_id = s[:id]
    
    s.reject{|k, v| [:id, :team_members_authentication_ids, :main_contact_authentication_id].include?(k) }.each do |k, v|
      startup.send("#{k}=".to_sym, v)
    end

    m = Meeting.where(:location_name => s[:location]).first
    startup.meeting_id = m.id unless m.blank?

    unless s[:stage].blank?
      startup.stage = Settings.startup_options.stage.to_hash.stringify_keys[s[:stage]]
    end
    unless s[:company_goal].blank?
      startup.company_goal = Settings.startup_options.company_goal.to_hash.stringify_keys[s[:company_goal]]
    end
    unless s[:growth_model].blank?
      startup.growth_model = Settings.startup_options.growth_model.to_hash.stringify_keys[s[:growth_model]]
    end

    if startup.save!(:validate => false)
      old_startup_ids[old_startup_id] = startup.id

      unless team_members_authentication_ids.blank?
        team_members_authentication_ids.each do |auth_id|
          next if auth_id.blank?
          auth = auth_by_id[auth_id.to_sym]
          if auth and auth[:user_id]
            u = User.find(auth[:user_id])
            u.startup_id = startup.id
            u.save(:validate => false)
          end
        end
      end
    else
      failed[:startup].push(s)
    end
  end

  failed[:checkin] = []
  data[:checkin].each do |c|
    next if c.blank?
    c.symbolize_keys!
    startup_id = old_startup_ids[c[:startup_id]]
    if !startup_id.blank?
      checkin = Checkin.new
      checkin.startup_id = startup_id
      c.reject{|k, v| k == :startup_id }.each do |k, v|
        checkin.send("#{k}=".to_sym, v)
      end

      failed[:checkin].push(c) unless checkin.save!
    else
      failed[:checkin].push(c)
    end
  end
end

puts failed.inspect