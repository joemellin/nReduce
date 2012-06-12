# Create default user

unless User.where(:email => 'josh@nreduce.com').count > 0
  u = User.new(:name => 'Josh', :email => 'josh@nreduce.com', :password => 'bHAxMBr8', :password_confirmation => 'bHAxMBr8')
  u.admin = true
  u.save
end

# Seed from exported yaml files on old site

file = File.open("#{Rails.root}/lib/data/models.json", "rb")
contents = file.read
data = JSON.parse(contents)

unless data.blank?
  auth_by_id = data[:authentication].inject({}){|res, e| res[e.id] = e; res }
  failed = {}
  failed[:user] = {}
  data[:user].each do |u|
    user = User.new

    auth_id = u[:authentication_id]
    u.delete(:authentication_id)

    # Use 'send' to call the attributes= method on the object and ignore attr_accesible limitations
    user.send :attributes=, u, false

    user.authentications.build(auth_by_id[auth_id])
    # Save the object
    if user.save
      auth_by_id[:user_id] = user.id
    else
      failed[:user].push(u)
    end
  end

  failed[:meeting] = {}
  data[:location].each do |l|
    meeting = Meeting.new
    unless l[:organizer_authentication_ids].blank?
      org = auth_by_id[l[:organizer_authentication_ids].first]
      meeting.organizer_id = org[:user_id] if !org.blank?
    end
    l.delete(:organizer_authentication_ids)
    meeting.send :attributes=, l, false
    failed[:meeting].push(l) unless m.save
  end

  old_startup_ids = {}
  failed[:startup] = {}
  data[:startup].each do |s|


    startup = Startup.new
    unless s[:main_contact_authentication_id].blank?
      auth = auth_by_id[s[:main_contact_authentication_id]]
      startup.main_contact_id = auth[:user_id] if auth and auth[:user_id]
    end
    s.delete(:main_contact_authentication_id)
    team_members_authentication_ids = s[:team_members_authentication_ids]
    s.delete(:team_members_authentication_ids)
    old_startup_id = s[:id]
    s.delete(:id)
    
    startup.send :attributes=, s, false

    if startup.save
      old_startup_ids[old_startup_id] = startup.id

      unless team_members_authentication_ids.blank?
        team_members_authentication_ids.each do |auth_id|
          auth = auth_by_id[auth_id]
          if auth and auth[:user_id]
            u = User.find(auth[:user_id])
            u.update_attribute('startup_id', startup.id)
          end
        end
      end
    else
      failed[:startup].push(s)
    end
  end

  failed[:checkin] = {}
  data[:checkin].each do |c|
    startup_id = old_startup_ids[c[:startup_id]]
    if startup_id.blank?
      c.delete(:startup_id)
      checkin = Checkin.new
      checkin.send :attributes=, c, false
      failed[:checkin].push(c) unless checkin.save
    else
      failed[:checkin].push(c)
    end
  end
end

puts failed.inspect