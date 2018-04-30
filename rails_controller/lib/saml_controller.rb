class SamlController < DummyController
  attr_reader :saml_destination_path

  def create
    identity_provider = SamlIdentityProvider.for_identity_provider_id(params[:idp])
    response          = Response.for(identity_provider.issuer, params[:SAMLResponse])
    saml_settings     = OneLoginSamlSettings.new

    saml_settings.assertion_consumer_service_url = create_saml_url(deployment_code: identity_provider.deployment_code)
    saml_settings.issuer                         = identity_provider.issuer
    saml_settings.idp_sso_target_url             = identity_provider.target_url
    saml_settings.idp_cert_fingerprint           = identity_provider.fingerprint

    response.settings = saml_settings

    saml_identity = identity_provider.saml_identity_for_name_id(response.name_id)

    ### Begin Account Section
    # See comment about the advisability of this below.
    ###
    account = LoginAccount.for(self, response, identity_provider, saml_identity)
    account.process

    # if !response.is_valid?
    #   path = root_path
    # end

    # if response.is_valid? && saml_identity.account_id
    #   path = redirect_path
    #   log_in_as saml_identity.account
    # end

    # if response.is_valid? && !saml_identity.account_id && (consumer_application = saml_identity.consumer_application)
    #   path = redirect_path
    #   session[ConsumerApplication::SESSION_KEY] = consumer_application.to_param
    # end

    # if response.is_valid? && !saml_identity.account_id && !consumer_application
    #   path = deployment_shortcode_path(identity_provider.deployment_code)
    #   session[:saml_attributes] = identity_provider.translated_attributes(response.attributes)
    #   session[:saml_identity_id] = saml_identity.to_param
    # end

    ### End Account Section, but notice that if swap the comments above, you have to change the 'account.path' line below to just 'path'.

    Renderer.for(
      self,
      identity_provider.test_mode? ? 'test' : 'normal',
      response.errors,
      account.path).render
  end
end

###################
# Different kinds of accounts.
# I'm extremely uncertain about this.  Seems like the confusion between response, identity_provider and saml_identity
# should perhaps get fixed first.
# Might be best to extract an object to hold the procedure that is the #create method, and then refactor from there.
###################
class LoginAccount
  def self.for(controller, response, identity_provider, saml_identity)
    return InvalidAccount.new(controller, response, identity_provider, saml_identity)             if !response.is_valid?
    return SamlAccount.new(controller, response, identity_provider, saml_identity)                if response.is_valid? && saml_identity.account_id
    return ConsumerApplicationAccount.new(controller, response, identity_provider, saml_identity) if response.is_valid? && !saml_identity.account_id && saml_identity.consumer_application
    return InitialAccount.new(controller, response, identity_provider, saml_identity)
    raise "Wut?"
  end

  attr_reader :controller,:response, :identity_provider, :saml_identity

  def initialize(controller, response, identity_provider, saml_identity)
    @controller         = controller
    @response           = response
    @identity_provider  = identity_provider
    @saml_identity      = saml_identity
  end
end

class InvalidAccount < LoginAccount
  def path
    controller.root_path
  end

  def process
  end
end

class SamlAccount < LoginAccount
  def path
    controller.redirect_path
  end

  def process
    controller.log_in_as(saml_identity.account)
  end
end

class ConsumerApplicationAccount < LoginAccount
  def path
    controller.redirect_path
  end

  def process
    controller.session[ConsumerApplication::SESSION_KEY] = saml_identity.consumer_application.to_param
  end
end

class InitialAccount < LoginAccount
  def path
    path = controller.deployment_shortcode_path(identity_provider.deployment_code)
  end

  def process
    controller.session[:saml_attributes]  = identity_provider.translated_attributes(response.attributes)
    controller.session[:saml_identity_id] = saml_identity.to_param
  end
end

###################
# Rendering
###################
# I'd do this if there were 3+ kinds of renderers, or if the logic was truely heinous.
# This logic should stay in the same file as the controller.
class Renderer
  def self.for(controller, mode, errors, path)
    if mode == 'test'
      InterstitialRenderer.new(controller, errors, path)
    else
      RegularRenderer.new(controller, errors, path)
    end
  end

  attr_reader :controller, :errors, :path

  def initialize(controller, errors, path)
    @controller = controller
    @errors     = errors
    @path       = path
  end
end

class InterstitialRenderer < Renderer
  def render
    controller.instance_variable_set(:@validation_errors, errors)
    controller.instance_variable_set(:@saml_destination_path, path)
    controller.render("test_interstitial")
  end
end

class RegularRenderer < Renderer
  def render
    controller.redirect_to(path)
  end
end