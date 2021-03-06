# -*- encoding : utf-8 -*-

DEPRECATED = { site_key: :public_key, secret_key: :private_key }

# card config overrides application.rb config overrides default
def load_recaptcha_config setting
  setting = "recaptcha_#{setting}".to_sym
  Cardio.config.send(
    "#{setting}=", load_recaptcha_card_config(setting) || # card content
    Cardio.config.send(setting) ||                        # application.rb
    (DEPRECATED[setting] && Cardio.config.send(DEPRECATED[setting])) ||
    default_setting(setting)
  )
end

def default_setting setting
  # when creating the database (with `decko seed`) this is called
  # but fails because Card::Auth doesn't exist
  return unless Card.const_defined? "Auth"
  Card::Auth::Permissions::RECAPTCHA_DEFAULTS[setting]
end

def card_table_ready?
  # FIXME: this test should be more generally usable
  ActiveRecord::Base.connection.table_exists?("cards") &&
    Card.ancestors.include?(ActiveRecord::Base)
end

# use if card with value is present
def load_recaptcha_card_config setting
  card = Card.find_by_codename setting
  card&.db_content.present? && card.db_content
end

ActiveSupport.on_load :after_card do
  Recaptcha.configure do |config|
    # the seed task runs initializers so we have to check
    # if the cards table is ready before we use it here
    if card_table_ready?
      %i[site_key secret_key].each do |setting|
        config.send "#{setting}=", load_recaptcha_config(setting)
      end
    end
    config.verify_url = "https://www.google.com/recaptcha/api/siteverify"
  end
end
