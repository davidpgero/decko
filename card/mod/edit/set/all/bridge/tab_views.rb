format :html do
  RELATED_ITEMS = [["children",       :children],
                   # ["mates",          "bed",          "*mates"],
                   # FIXME: optimize and restore
                   ["references out", :refers_to],
                   ["references in",  :referred_to_by]].freeze

  view :engage_tab, wrap: { div: { class: "m-3 mt-4" } } do
    [render_follow_section, discussion_section].compact
  end

  view :history_tab do
    class_up "d0-card-body",  "history-slot"
    voo.hide :act_legend
    acts_bridge_layout card.history_acts
  end

  view :related_tab do
    bridge_pills bridge_pill_items(RELATED_ITEMS, "Related")
  end

  view :rules_tab, wrap: :slot do
    class_up "card-slot", "flex-column", true
    wrap do
      nest current_set_card, view: :bridge_rules_tab
    end
  end

  view :account_tab do
    bridge_pills bridge_pill_items(account_items, "Account")
  end

  view :follow_section, wrap: :slot do
    follow_section
  end

  def discussion_section
    return unless show_discussion?
    field_nest(:discussion, view: :titled, title: "Discussion", show: :comment_box,
               hide: [:menu])
  end

  def account_items
    %i[account roles created edited follow].map do |item|
      if item == :account
        [tr(:details), item, bridge_link_opts(path: { view: :edit, hide: [:edit_name_row, :edit_type_row], layout: :overlay })]
      else
        [tr(item), item]
      end
    end
  end

  def bridge_pills items
    list_tag class: "nav nav-pills bridge-pills flex-column", items: { class: "nav-item" } do
      items
    end
  end

  def bridge_pill_items data, breadcrumb
    data.map do |text, field, extra_opts|
      opts = bridge_link_opts.merge("data-toggle": "pill")
      add_class opts, "nav-link"
      opts.merge! breadcrumb_data(breadcrumb)
      opts.merge! extra_opts if extra_opts
      link_to_card [card, field], text,  opts
    end
  end
end