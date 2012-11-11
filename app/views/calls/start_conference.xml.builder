xml.instruct!
xml.Response do
  xml.Dial do
    xml.Conference{:beep => false, :waitUrl => nil, :startConferenceOnEnter => true, :endConferenceOnExit => true} NoMusicNoBeepRoom
  end
end