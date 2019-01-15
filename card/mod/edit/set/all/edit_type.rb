format :html do
  view :edit_type, cache: :never, perms: :update do
    frame do
      _render_edit_type_form
    end
  end

  view :edit_type_form, cache: :never, perms: :update, wrap: :slot do
    card_form :update do
      output [hidden_edit_type_fields,
              _render_type_formgroup,
              edit_type_buttons]
    end
  end

  def hidden_edit_type_fields
    # because the content editor can change with a type change
    # we have to reload the whole edit view
    hidden_field_tag "success[view]", "edit"
  end

  def edit_type_buttons
    cancel_path = path view: :edit
    button_formgroup do
      [standard_submit_button, standard_cancel_button(href: cancel_path)]
    end
  end
end