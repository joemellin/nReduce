module ConversationsHelper
  def time_for_conversation(time) 
    if time > Time.now.beginning_of_day
      return time.strftime("%-l:%M%P")
    else
      if time > Time.now.beginning_of_week
        return time.strftime("%a")
      else
        return time.strftime("%b %-d")
      end
    end
  end

  def link_to_message_startup(startup)
    link_to '<i class="icon-envelope"></i> Message'.html_safe, new_conversation_path(:startup_id => startup.to_param), :class => 'btn'
  end

  def link_to_message_user(user)
    link_to '<i class="icon-envelope"></i> Message'.html_safe, new_conversation_path(:participant_ids => [user.id].join('|')), :class => 'btn'
  end
end
