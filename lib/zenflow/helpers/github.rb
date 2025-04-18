module Zenflow
  # GitHub communication methods
  class Github
    attr_accessor :hub

    DEFAULT_HUB = 'github.com'

    DEFAULT_API_BASE_URL = 'https://api.github.com'
    DEFAULT_USER_AGENT_BASE = 'Zencoder'

    API_BASE_URL_KEY = 'api.base.url'
    USER_KEY = 'github.user'
    TOKEN_KEY = 'token'
    USER_AGENT_BASE_KEY = 'user.agent.base'

    CONFIG_KEYS = [
      API_BASE_URL_KEY,
      USER_KEY,
      TOKEN_KEY,
      USER_AGENT_BASE_KEY
    ]

    def initialize(hub)
      @hub = hub
    end

    def self.current
      Github.new(Zenflow::Repo.hub || DEFAULT_HUB)
    end

    CURRENT = current

    def config
      set_api_base_url
      set_user
      set_user_agent_base
    end

    def api_base_url(use_default_when_value_is_nil = true)
      api_base_url_string = get_config(API_BASE_URL_KEY)
      api_base_url_string ||= DEFAULT_API_BASE_URL if use_default_when_value_is_nil
      api_base_url_string
    end

    def ask_should_update_base_api_url?
      Zenflow::Requests.ask(
        "The GitHub API base URL for this hub is currently #{api_base_url(false)}. Do you want to use that?",
        options: ["Y", "n"],
        default: "y"
      ) == "n"
    end

    def set_api_base_url
      return unless api_base_url(false).nil? || ask_should_update_base_api_url?

      api_base_url_string = Zenflow::Requests.ask(
        "What is the base URL of your Github API?",
        { default: DEFAULT_API_BASE_URL }
      )
      set_config(API_BASE_URL_KEY, api_base_url_string)
    end

    def user
      get_config(USER_KEY)
    end

    def ask_should_update_user?
      Zenflow::Requests.ask(
        "The GitHub user for this hub is currently #{user}. Do you want to use that?",
        options: ["Y", "n"],
        default: "y"
      ) == "n"
    end

    def set_user
      return unless user.nil? || ask_should_update_user?

      username = Zenflow::Requests.ask("What is your Github username?")
      set_config(USER_KEY, username)
    end

    def zenflow_token
      get_config(TOKEN_KEY)
    end

    def ask_should_update_zenflow_token?
      Zenflow::Requests.ask(
        "You already have a token from GitHub. Do you want to set a new one?",
        options: ["y", "N"],
        default: "n"
      ) == "y"
    end

    def authorize
      return unless zenflow_token.nil? || ask_should_update_zenflow_token?

      Zenflow::Log("Authorizing with GitHub (#{user}@#{@hub})... Enter your GitHub password.")
      oauth_response = JSON.parse(
        Zenflow::Shell.run(
          %(curl -u "#{user}" #{api_base_url}/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent),
          silent: true
        )
      )
      if oauth_response['token']
        set_config(TOKEN_KEY, oauth_response['token'])
        Zenflow::Log("Authorized!")
      else
        Zenflow::Log("Something went wrong. Error from GitHub was: #{oauth_response['message']}")
      end
    end

    def user_agent_base(use_default_when_value_is_nil = true)
      user_agent_base = get_config(USER_AGENT_BASE_KEY)
      user_agent_base ||= DEFAULT_USER_AGENT_BASE if use_default_when_value_is_nil
      user_agent_base
    end

    def ask_should_update_user_agent_base?
      Zenflow::Requests.ask(
        "The GitHub User Agent base for this hub is currently #{user_agent_base(false)}. Do you want to use that?",
        options: ["Y", "n"],
        default: "y"
      ) == "n"
    end

    def set_user_agent_base
      return unless user_agent_base(false).nil? || ask_should_update_user_agent_base?

      user_agent_base = Zenflow::Requests.ask(
        "What base string would you like to use for the User Agent header, 'User-Agent: [user-agent-base]/Zenflow-#{VERSION}?",
        { default: DEFAULT_USER_AGENT_BASE }
      )
      set_config(USER_AGENT_BASE_KEY, user_agent_base)
    end

    # If this repo is not hosted on the default github, construct a key prefix containing the hub information
    def parameter_key_for_hub(key)
      default_hub_key_prefix = key == USER_KEY ? "" : "zenflow."  # preserves backwards compatibility
      default_hub? ? "#{default_hub_key_prefix}#{key}" : "zenflow.hub.#{@hub}.#{key}"
    end

    def get_config(base_parameter_key)
      parameter_key_for_hub = parameter_key_for_hub(base_parameter_key)
      get_global_config(parameter_key_for_hub)
    end

    def set_config(base_parameter_key, value)
      parameter_key_for_hub = parameter_key_for_hub(base_parameter_key)
      set_global_config(parameter_key_for_hub, value)
    end

    def get_global_config(key)
      config = Zenflow::Shell.run("git config --get #{key}", silent: true)
      config = config.chomp unless config.nil?
      config.to_s == '' ? nil : config
    end

    def set_global_config(key, value)
      Zenflow::Shell.run("git config --global #{key} #{value}", silent: true)
    end

    def default_hub?
      @hub == DEFAULT_HUB
    end

    def describe_parameter(name, parameter_key, value)
      [name, parameter_key_for_hub(parameter_key), get_config(parameter_key), value]
    end

    def describe
      [
        describe_parameter("API Base URL",    API_BASE_URL_KEY,    api_base_url),
        describe_parameter("User",            USER_KEY,            user),
        describe_parameter("Token",           TOKEN_KEY,           zenflow_token),
        describe_parameter("User Agent Base", USER_AGENT_BASE_KEY, user_agent_base)
      ]
    end
  end

  class GithubRequest
    include HTTParty
    base_uri "#{Github::CURRENT.api_base_url}/repos/#{Zenflow::Repo.slug}"
    format :json
    headers "Authorization" => "token #{Github::CURRENT.zenflow_token}"
    headers "User-Agent" => "#{Github::CURRENT.user_agent_base}/Zenflow-#{VERSION}"
  end
end
