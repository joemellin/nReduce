xml.instruct!
xml.Response do
  xml.Dial(:timeout => 10, :action => connected_calls_path) @number
end