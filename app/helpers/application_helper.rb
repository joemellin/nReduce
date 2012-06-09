module ApplicationHelper

  def js_settings
    %{
      <script type="text/javascript" charset="utf-8">
        window.Settings = {};
        Settings.env = "#{Rails.env}";
        Settings.client = #{Settings.client.to_hash.to_json};
      </script>
    }.html_safe
  end


  # set attributes that display on the body
  def body_attrs(val = nil)
    @body_attrs ||= {}
    @body_attrs = @body_attrs.with_indifferent_access

    # merge values
    @body_attrs.merge!(val.with_indifferent_access) if val.is_a?(Hash)

    @body_attrs
  end

  # add css class
  def error_css(model, field)
    return unless model.present?

    css_classes = []

    css_classes << "with-errors" if model.errors[field].present?

    {
      :class => css_classes.join(" ")
    }
  end

  def agree_error_msg(model, field)
    return unless model.present?

    if model.errors[field].present?
      %{
        <ul class="errors">
          <li>Required. Please read and select a response.</li>
        </ul>
      }.html_safe
    end
  end

  def link_to_twitter(handle, opts = {})
    link_to(handle, "https://twitter.com/#!/#{handle.sub('@', '')}", opts)
  end

  def is_controller_action?(controller_name, action_name)
    controller.controller_name == controller_name and controller.action_name == action_name
  end

  def registration_open?
    false
  end
end
