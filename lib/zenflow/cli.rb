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
        set_up_version_file
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

        if Zenflow::Requests.ask(
          "Configure GitHub authentication now? (Can be done later)",
          options: ["y", "N"],
          default: "n"
        ) == "y"
          Zenflow::Github::CURRENT.authorize
        else
          Zenflow::Log("Skipping GitHub authentication. You can add it later with `zenflow admin github`.", color: :yellow)
        end
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
          "What is the name of the primary development branch?",
          default: "main"
        )
        configure_branch(:staging_branch,
          "Use a branch for staging releases?",
          "staging"
        )
        configure_branch(:qa_branch, "Use a branch for QA releases?", "qa")
        configure_branch(:release_branch, "Use a branch for production releases?", "production")
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

      def set_up_version_file
        return if File.exist?("VERSION.yml")

        Zenflow::Log("Version Management")
        if Zenflow::Requests.ask(
          "Set up a VERSION.yml file?",
          options: ["Y", "n"], default: "y"
        ) == "y"
          initial_version = {
            "major" => 0,
            "minor" => 1,
            "patch" => 0,
            "pre" => nil
          }
          File.open("VERSION.yml", "w") do |file|
            YAML.dump(initial_version, file)
          end
          Zenflow::Log("Created VERSION.yml with initial version 0.1.0", color: :green)
        end
      end
    end
  end
end
