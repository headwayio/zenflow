# Main Zenflow Module
module Zenflow
  def self.Deploy(to, opts = {})
    bundle_exec = ''
    bundle_exec = 'bundle exec ' if File.exist?('./Gemfile')

    Branch.push(to)
    command = if opts[:migrations]
      Log("Deploying with migrations to #{to}")
      "#{bundle_exec}cap #{to} deploy:migrations"
    else
      Log("Deploying to #{to}")
      "#{bundle_exec}cap #{to} deploy"
    end

    command += " --trace" if opts[:trace]

    Shell[command]
  end

  # Deployment sub-commands
  class Deploy < Thor
    class_option :migrations, type: :boolean, desc: "Run migrations during deployment", aliases: :m
    class_option :trace, type: :boolean, desc: "Run capistrano trace option", aliases: :t

    desc "qa", "Deploy to qa."
    def qa
      Zenflow::Deploy("qa", options)
    end

    desc "staging", "Deploy to staging."
    def staging
      Zenflow::Deploy("staging", options)
    end

    desc "production", "Deploy to production."
    def production
      Zenflow::Deploy("production", options)
    end
  end
end
