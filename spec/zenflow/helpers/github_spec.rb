require 'spec_helper'

describe Zenflow::Github do
  describe '.api_base_url' do
    context 'when the value is present' do
      let(:hub) { Zenflow::Github.new('test-hub') }

      before(:each) do
        expect(hub).to receive(:get_config).with('api.base.url').and_return("api-base-url")
      end

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.api_base_url).to eq("api-base-url")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.api_base_url(true)).to eq("api-base-url")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.api_base_url(false)).to eq("api-base-url")
        end
      end
    end

    context 'when the value is absent' do
      let(:hub) { Zenflow::Github.new('test-hub') }

      before(:each) do
        expect(hub).to receive(:get_config).with('api.base.url').and_return(nil)
      end

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.api_base_url).to eq("https://api.github.com")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.api_base_url(true)).to eq("https://api.github.com")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.api_base_url(false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_api_base_url' do
    it 'asks for the API base URL and sets it to zenflow.api.base.url' do
    end
  end

  describe '.set_api_base_url' do
    let(:hub) { Zenflow::Github.new('test-hub') }
    let(:api_base_url) { 'api-base-url' }

    context 'when a github api base url is already saved' do
      before do
        expect(hub).to receive(:api_base_url).twice.and_return(api_base_url)
      end

      context 'and the user decides to set a new one' do
        before do
          expect(Zenflow::Requests).to receive(:ask).and_return('n')
        end

        it 'asks for an api base url' do
          expect(Zenflow::Requests).to receive(:ask).and_return(api_base_url)
          expect(hub).to receive(:set_config).with('api.base.url', api_base_url)
          hub.set_api_base_url
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          expect(Zenflow::Requests).to receive(:ask).and_return('y')
        end

        it 'does not ask for an api base url' do
          expect(Zenflow::Requests).to_not receive(:ask)
          expect(hub).to_not receive(:set_config)
          hub.set_api_base_url
        end
      end
    end

    context 'when an api base url is not already saved' do
      before do
        expect(hub).to receive(:api_base_url).and_return(nil)
      end

      it 'asks for an api base url' do
        expect(Zenflow::Requests).to receive(:ask).and_return(api_base_url)
        expect(hub).to receive(:set_config).with('api.base.url', api_base_url)
        hub.set_api_base_url
      end
    end
  end

  describe '.user' do
    let(:hub) { Zenflow::Github.new('hub') }
    let(:user) { 'github-user' }

    before(:each) do
      expect(hub).to receive(:get_config).with('github.user').and_return(user)
    end

    it "returns the user" do
      expect(hub.user).to eq(user)
    end
  end

  describe '.set_user' do
    let(:hub) { Zenflow::Github.new('test-hub') }
    let(:user) { 'github-user' }

    context 'when a github user is already saved' do
      before do
        expect(hub).to receive(:user).twice.and_return(user)
      end

      context 'and the user decides to set a new one' do
        before do
          expect(Zenflow::Requests).to receive(:ask).and_return('n')
        end

        it 'asks for a user' do
          expect(Zenflow::Requests).to receive(:ask).and_return(user)
          expect(hub).to receive(:set_config).with('github.user', user)
          hub.set_user
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          expect(Zenflow::Requests).to receive(:ask).and_return('y')
        end

        it 'does not ask for a user' do
          expect(Zenflow::Requests).to_not receive(:ask)
          expect(hub).to_not receive(:set_config)
          hub.set_user
        end
      end
    end

    context 'when a user is not already saved' do
      before do
        expect(hub).to receive(:user).and_return(nil)
      end

      it 'asks for a user' do
        expect(Zenflow::Requests).to receive(:ask).and_return(user)
        expect(hub).to receive(:set_config).with('github.user', user)
        hub.set_user
      end
    end
  end

  describe '.authorize' do
    let(:hub) { Zenflow::Github.new('my-hub') }

    context 'when a zenflow_token is already saved' do
      before do
        expect(hub).to receive(:zenflow_token).and_return('super secret token')
      end

      context 'and the user decides to set a new one' do
        before do
          expect(Zenflow::Requests).to(
            receive(:ask)
            .with(
              "You already have a token from GitHub. Do you want to set a new one?",
              options: ["y", "N"],
              default: "n"
            ).and_return('y')
          )
        end

        context 'and authorization succeeds' do
          before do
            # New authentication messages
            expect(Zenflow).to receive("Log").with("GitHub authentication is required for some Zenflow operations", color: :yellow)
            expect(Zenflow).to receive("Log").with("Please create a Personal Access Token at https://github.com/settings/tokens", color: :yellow)
            expect(Zenflow).to receive("Log").with("   with 'repo' scope selected", color: :yellow)

            # Ask for token
            expect(Zenflow::Requests).to receive(:ask).with("Enter your GitHub Personal Access Token:", required: true).and_return("test-token")

            # API call with token
            expect(hub).to receive(:api_base_url).and_return('https://api.base.url')
            expect(Zenflow::Shell).to(
              receive(:run)
              .with(
                %{curl -H "Authorization: token test-token" https://api.base.url/user --silent},
                silent: true
              ).and_return('{"login": "adamkittelson"}')
            )
          end

          it 'authorizes with Github' do
            expect(hub).to receive(:set_config).with('token', "test-token")
            expect(Zenflow).to receive("Log").with("Authorized as adamkittelson!", color: :green)
            hub.authorize
          end
        end

        context 'and authorization fails' do
          before do
            # New authentication messages
            expect(Zenflow).to receive("Log").with("GitHub authentication is required for some Zenflow operations", color: :yellow)
            expect(Zenflow).to receive("Log").with("Please create a Personal Access Token at https://github.com/settings/tokens", color: :yellow)
            expect(Zenflow).to receive("Log").with("   with 'repo' scope selected", color: :yellow)

            # Ask for token
            expect(Zenflow::Requests).to receive(:ask).with("Enter your GitHub Personal Access Token:", required: true).and_return("invalid-token")

            # API call with invalid token
            expect(hub).to receive(:api_base_url).and_return('https://api.base.url')
            expect(Zenflow::Shell).to(
              receive(:run)
              .with(
                %{curl -H "Authorization: token invalid-token" https://api.base.url/user --silent},
                silent: true
              ).and_return('{"message": "Bad credentials"}')
            )

            # Prompt to try again
            expect(Zenflow).to receive("Log").with("Token verification failed. Please check your token and try again.", color: :red)
            expect(Zenflow::Requests).to receive(:ask).with(
              "Would you like to try entering your token again?",
              options: ["Y", "n"],
              default: "y"
            ).and_return("n")
          end

          it 'handles the failed authorization' do
            expect(Zenflow).to receive("Log").with("GitHub authentication cancelled. Some features may not work properly.", color: :yellow)
            hub.authorize
          end
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          expect(Zenflow::Requests).to receive(:ask).and_return('n')
        end

        it 'does not authorize with Github' do
          hub.authorize
        end
      end
    end

    context 'when a zenflow_token is not already saved' do
      before do
        expect(hub).to receive(:zenflow_token).and_return(nil)
      end

      context 'and authorization succeeds' do
        before do
          # New authentication messages
          expect(Zenflow).to receive("Log").with("GitHub authentication is required for some Zenflow operations", color: :yellow)
          expect(Zenflow).to receive("Log").with("Please create a Personal Access Token at https://github.com/settings/tokens", color: :yellow)
          expect(Zenflow).to receive("Log").with("   with 'repo' scope selected", color: :yellow)

          # Ask for token
          expect(Zenflow::Requests).to receive(:ask).with("Enter your GitHub Personal Access Token:", required: true).and_return("new-token")

          # API call with token
          expect(hub).to receive(:api_base_url).and_return('https://api.base.url')
          expect(Zenflow::Shell).to(
            receive(:run)
            .with(
              %{curl -H "Authorization: token new-token" https://api.base.url/user --silent},
              silent: true
            ).and_return('{"login": "adamkittelson"}')
          )
        end

        it 'authorizes with Github' do
          expect(hub).to receive(:set_config).with('token', "new-token")
          expect(Zenflow).to receive("Log").with("Authorized as adamkittelson!", color: :green)
          hub.authorize
        end
      end

      context 'and authorization fails' do
        before do
          # New authentication messages
          expect(Zenflow).to receive("Log").with("GitHub authentication is required for some Zenflow operations", color: :yellow)
          expect(Zenflow).to receive("Log").with("Please create a Personal Access Token at https://github.com/settings/tokens", color: :yellow)
          expect(Zenflow).to receive("Log").with("   with 'repo' scope selected", color: :yellow)

          # Ask for token
          expect(Zenflow::Requests).to receive(:ask).with("Enter your GitHub Personal Access Token:", required: true).and_return("bad-token")

          # API call with invalid token
          expect(hub).to receive(:api_base_url).and_return('https://api.base.url')
          expect(Zenflow::Shell).to(
            receive(:run)
            .with(
              %{curl -H "Authorization: token bad-token" https://api.base.url/user --silent},
              silent: true
            ).and_return('{"message": "Bad credentials"}')
          )

          # Prompt to try again
          expect(Zenflow).to receive("Log").with("Token verification failed. Please check your token and try again.", color: :red)
          expect(Zenflow::Requests).to receive(:ask).with(
            "Would you like to try entering your token again?",
            options: ["Y", "n"],
            default: "y"
          ).and_return("n")
        end

        it 'handles the failed authorization' do
          expect(Zenflow).to receive("Log").with("GitHub authentication cancelled. Some features may not work properly.", color: :yellow)
          hub.authorize
        end
      end
    end
  end

  describe '.user_agent_base' do
    let(:hub) { Zenflow::Github.new('hub') }

    context 'when the value is present' do
      before(:each) do
        expect(hub).to receive(:get_config).with('user.agent.base').and_return("user-agent-base")
      end

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.user_agent_base).to eq("user-agent-base")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(true)).to eq("user-agent-base")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(false)).to eq("user-agent-base")
        end
      end
    end

    context 'when the value is absent' do
      before(:each) do
        expect(hub).to receive(:get_config).with('user.agent.base').and_return(nil)
      end

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.user_agent_base).to eq("Zencoder")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(true)).to eq("Zencoder")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_user_agent_base' do
    let(:hub) { Zenflow::Github.new('test-hub') }
    let(:user_agent_base) { 'user-agent-base' }

    context 'when a github user agent base is already saved' do
      before do
        expect(hub).to receive(:user_agent_base).twice.and_return(user_agent_base)
      end

      context 'and the user decides to set a new one' do
        before do
          expect(Zenflow::Requests).to receive(:ask).and_return('n')
        end

        it 'asks for a user agent base' do
          expect(Zenflow::Requests).to receive(:ask).and_return(user_agent_base)
          expect(hub).to receive(:set_config).with('user.agent.base', user_agent_base)
          hub.set_user_agent_base
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          expect(Zenflow::Requests).to receive(:ask).and_return('y')
        end

        it 'does not ask for a user agent base' do
          expect(Zenflow::Requests).to_not receive(:ask)
          expect(hub).to_not receive(:set_config)
          hub.set_user_agent_base
        end
      end
    end

    context 'when a user agent base is not already saved' do
      before do
        expect(hub).to receive(:user_agent_base).and_return(nil)
      end

      it 'asks for a user agent base' do
        expect(Zenflow::Requests).to receive(:ask).and_return(user_agent_base)
        expect(hub).to receive(:set_config).with('user.agent.base', user_agent_base)
        hub.set_user_agent_base
      end
    end
  end

  describe '.current' do
    context 'when the current repo is nil' do
      before(:each) do
        expect(Zenflow::Repo).to receive(:hub).and_return(nil)
      end

      it 'returns the default hub' do
        expect(Zenflow::Github.current.hub).to eq 'github.com'
      end
    end

    context 'when the current repo is not nil' do
      before(:each) do
        expect(Zenflow::Repo).to receive(:hub).and_return('current.repo.hub')
      end

      it 'returns the current repo\'s hub' do
        expect(Zenflow::Github.current.hub).to eq 'current.repo.hub'
      end
    end
  end

  describe '.parameter_key_for_hub' do
    context 'when hub is the default hub' do
      let(:hub) { Zenflow::Github.new('github.com') }

      context 'and key is the api url base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(hub.parameter_key_for_hub('api.base.url')).to eq("zenflow.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'does not prepend a prefix' do
          expect(hub.parameter_key_for_hub('github.user')).to eq('github.user')
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(hub.parameter_key_for_hub('token')).to eq("zenflow.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(hub.parameter_key_for_hub('user.agent.base')).to eq("zenflow.user.agent.base")
        end
      end
    end

    context 'hub is not the default hub' do
      let(:hub) { Zenflow::Github.new('my-hub') }

      context 'and key is the api url base key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('api.base.url')).to eq("zenflow.hub.my-hub.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('github.user')).to eq("zenflow.hub.my-hub.github.user")
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('token')).to eq("zenflow.hub.my-hub.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('user.agent.base')).to eq("zenflow.hub.my-hub.user.agent.base")
        end
      end
    end
  end

  describe '.get_config' do
    let(:hub) { Zenflow::Github.new('test-hub') }

    it 'gets the correct global config parameter' do
      expect(hub).to receive(:get_global_config).with("zenflow.hub.test-hub.test-key")
      hub.get_config('test-key')
    end
  end

  describe '.set_config' do
    let(:hub) { Zenflow::Github.new('test-hub') }

    it 'sets the correct global config parameter' do
      expect(hub).to receive(:set_global_config).with("zenflow.hub.test-hub.test-key", "test-value")
      hub.set_config('test-key', 'test-value')
    end
  end

  describe '.get_global_config' do
    let(:hub) { Zenflow::Github.new('test-hub') }

    context 'when value is present' do
      before(:each) do
        expect(Zenflow::Shell).to receive(:run).with('git config --get key', silent: true).and_return('value')
      end

      it 'returns the value' do
        expect(hub.get_global_config('key')).to eq('value')
      end
    end

    context 'when value is missing' do
      before(:each) do
        expect(Zenflow::Shell).to receive(:run).with('git config --get key', silent: true).and_return('')
      end

      it 'returns nil' do
        expect(hub.get_global_config('key')).to eq(nil)
      end
    end
  end

  describe '.set_global_config' do
    let(:hub) { Zenflow::Github.new('test-hub') }

    before(:each) do
      expect(Zenflow::Shell).to receive(:run).with('git config --global key value', silent: true)
    end

    it 'sets the value' do
      hub.set_global_config('key', 'value')
    end
  end

  describe '.config_keys' do
    it 'returns the expected array of keys' do
      expect(Zenflow::Github::CONFIG_KEYS).to eq(
        [
          'api.base.url',
          'github.user',
          'token',
          'user.agent.base'
        ]
      )
    end
  end

  describe '.describe_parameter' do
    let(:hub) { Zenflow::Github.new('my-hub') }

    it 'returns the expected array' do
      expect(hub).to receive(:get_config).with('key').and_return('config-value')

      expect(hub.describe_parameter('name', 'key', 'value')).to eq(
        ['name', 'zenflow.hub.my-hub.key', 'config-value', 'value']
      )
    end
  end

  describe '.describe' do
    context 'all parameters configured' do
      let(:hub) { Zenflow::Github.new('my-hub') }

      it 'returns the expected data' do
        expect(hub).to receive(:get_config).twice.with('api.base.url').and_return('api-base-url-config-value')
        expect(hub).to receive(:get_config).twice.with('github.user').and_return('github-user-config-value')
        expect(hub).to receive(:get_config).twice.with('token').and_return('token-config-value')
        expect(hub).to(
          receive(:get_config)
          .twice
          .with('user.agent.base')
          .and_return('user-agent-base-config-value')
        )

        expect(hub.describe).to eq(
          [
            ['API Base URL',    'zenflow.hub.my-hub.api.base.url',    'api-base-url-config-value',    'api-base-url-config-value'],
            ['User',            'zenflow.hub.my-hub.github.user',     'github-user-config-value',     'github-user-config-value'],
            ['Token',           'zenflow.hub.my-hub.token',           'token-config-value',           'token-config-value'],
            ['User Agent Base', 'zenflow.hub.my-hub.user.agent.base', 'user-agent-base-config-value', 'user-agent-base-config-value']
          ]
        )
      end
    end

    context 'no parameters configured' do
      let(:hub) { Zenflow::Github.new('my-hub') }

      it 'returns the expected data' do
        expect(hub).to receive(:get_config).twice.with('api.base.url').and_return(nil)
        expect(hub).to receive(:get_config).twice.with('github.user').and_return(nil)
        expect(hub).to receive(:get_config).twice.with('token').and_return(nil)
        expect(hub).to receive(:get_config).twice.with('user.agent.base').and_return(nil)

        expect(hub.describe).to eq(
          [
            ['API Base URL',    'zenflow.hub.my-hub.api.base.url',    nil, 'https://api.github.com'],
            ['User',            'zenflow.hub.my-hub.github.user',     nil, nil],
            ['Token',           'zenflow.hub.my-hub.token',           nil, nil],
            ['User Agent Base', 'zenflow.hub.my-hub.user.agent.base', nil, 'Zencoder']
          ]
        )
      end
    end

    context 'hub is default' do
      let(:hub) { Zenflow::Github.new(Zenflow::Github::DEFAULT_HUB) }

      it 'returns the expected data' do
        expect(hub).to receive(:get_config).twice.with('api.base.url').and_return(nil)
        expect(hub).to receive(:get_config).twice.with('github.user').and_return(nil)
        expect(hub).to receive(:get_config).twice.with('token').and_return(nil)
        expect(hub).to receive(:get_config).twice.with('user.agent.base').and_return(nil)

        expect(hub.describe).to eq(
          [
            ['API Base URL',    'zenflow.api.base.url',    nil, 'https://api.github.com'],
            ['User',            'github.user',             nil, nil],
            ['Token',           'zenflow.token',           nil, nil],
            ['User Agent Base', 'zenflow.user.agent.base', nil, 'Zencoder']
          ]
        )
      end
    end
  end
end
