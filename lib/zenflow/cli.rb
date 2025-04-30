module Zenflow
  # Entry point for all Zenflow command related stuff
  class CLI < Thor
    map "-v" => "version", "--version" => "version"
    map "-h" => "help", "--help" => "help"

    desc "version", "Show zenflow version.", hide: true
    def version
      puts "Zenflow #{Zenflow::VERSION}"
    end

    desc "help", "Show zenflow help.", hide: true
    def help
      version
      puts
      puts "Options:"
      puts "  -h, --help      # Prints help"
      puts "  -v, --version   # Prints Zenflow version"
      puts
      super
    end

    desc "admin SUBCOMMAND", "Manage Github server configurations."
    subcommand "admin", Zenflow::Admin

    desc "feature SUBCOMMAND", "Manage feature branches."
    subcommand "feature", Zenflow::Feature

    desc "chore SUBCOMMAND", "Manage chore branches."
    subcommand "chore", Zenflow::Chore

    desc "bug SUBCOMMAND", "Manage bug branches."
    subcommand "bug", Zenflow::Bug

    desc "hotfix SUBCOMMAND", "Manage hotfix branches."
    subcommand "hotfix", Zenflow::Hotfix

    desc "release SUBCOMMAND", "Manage release branches."
    subcommand "release", Zenflow::Release

    desc "reviews SUBCOMMAND", "Works with code reviews."
    subcommand "reviews", Zenflow::Reviews

    desc "deploy ENV", "Deploy to an environment."
    subcommand "deploy", Zenflow::Deploy

    desc "init", "Write the zenflow config file."
    def init(force = false)
      if Zenflow::Config.configured? && !force
        already_configured
      else
        configure_github
        configure_project
        configure_branches
        configure_merge_strategy
        configure_remotes
        confirm_some_stuff
        set_up_changelog
        Zenflow::Config.save!
      end
    end

    no_commands do
      def already_configured
        Zenflow::Log("Warning", color: :red)
        if Zenflow::Requests.ask(
          "There is an existing config file. Overwrite it?",
          options: ["y", "N"],
          default: "n"
        ) == "y"
          init(true)
        else
          Zenflow::Log("Aborting...", color: :red)
          exit(1)
        end
      end

      def configure_github
        if Zenflow::Github::CURRENT.default_hub?
          Zenflow::Github::CURRENT.set_user
        else
          Zenflow::Github::CURRENT.config
        end
        Zenflow::Github::CURRENT.authorize
      end

      def configure_project
        Zenflow::Log("Project")
        Zenflow::Config[:project] = Zenflow::Requests.ask(
          "What is the name of this project?",
          required: true
        )
      end

      def configure_branches
        Zenflow::Log("Branches")
        Zenflow::Config[:development_branch] = Zenflow::Requests.ask(
          "What is the name of the main development branch?",
          default: "master"
        )
        configure_branch(
          :staging_branch,
          "Use a branch for staging releases and hotfixes?",
          "staging"
        )
        configure_branch(:qa_branch, "Use a branch for testing features?", "qa")
        configure_branch(:release_branch, "Use a release branch?", "production")
      end

      def configure_branch(branch, question, default)
        if Zenflow::Requests.ask(question, options: ["Y", "n"], default: "y") == "y"
          Zenflow::Config[branch] = Zenflow::Requests.ask(
            "What is the name of that branch?",
            default: default
          )
        else
          Zenflow::Config[branch] = false
        end
      end

      def configure_remotes
        Zenflow::Config[:remote] = Zenflow::Requests.ask(
          "What is the name of your primary remote?",
          default: "origin"
        )
        if Zenflow::Requests.ask("Use a backup remote?", options: ["y", "N"], default: "n") == "y"
          Zenflow::Config[:backup_remote] = Zenflow::Requests.ask(
            "What is the name of your backup remote?",
            default: "backup"
          )
        else
          Zenflow::Config[:backup_remote] = false
        end
      end

      def configure_merge_strategy
        Zenflow::Config[:merge_strategy] = Zenflow::Requests.ask(
          "What merge strategy would you prefer?",
          default: "merge",
          options: ['merge', 'rebase']
        )
      end

      def confirm_some_stuff
        Zenflow::Log("Confirmations")
        Zenflow::Config[:confirm_staging] = Zenflow::Requests.ask(
          "Require deployment to a staging environment?",
          options: ["Y", "n"],
          default: "y"
        ) == "y"
        Zenflow::Config[:confirm_review] = Zenflow::Requests.ask(
          "Require code reviews?",
          options: ["Y", "n"], default: "y"
        ) == "y"
      end

      def set_up_changelog
        return if File.exist?("CHANGELOG.md")

        Zenflow::Log("Changelog Management")
        Zenflow::Changelog.create if Zenflow::Requests.ask(
          "Set up a changelog?",
          options: ["Y", "n"], default: "y"
        ) == "y"
      end
    end
  end
end
