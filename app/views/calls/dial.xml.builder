xml.instruct!
xml.Response {
  xml.Dial(@phone, :timeout => 10, :action => connected_calls_path)
}