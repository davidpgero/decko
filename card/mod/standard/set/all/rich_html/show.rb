format :html do
  def show view, args
    content = send "show_#{show_layout? ? :with : :without}_page_layout", view, args
    show_full_page? ? page_wrapper(content) : content
  end

  def show_without_page_layout view, args
    @main = true if params[:is_main] || args[:main]
    args.delete(:layout)
    view ||= args[:home_view] || :open
    render! view, args
  end

  def show_full_page?
    !Env.ajax?
  end

  def page_wrapper content
    <<-HTML.strip_heredoc
      <!DOCTYPE HTML>
      <html>
        <head>
          #{head_content}
        </head>
        <body class="right-sidebar">
          #{content}
        </body>
      </html>
    HTML
  end

  def head_content
    nest card.rule_card(:head), view: :item_cores
  end

  def with_main_opts args
    old_main_opts = @main_opts
    @main_opts = args
    yield
  ensure
    @main_opts = old_main_opts
  end
end
