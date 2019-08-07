require 'English'

namespace :db do # rubocop:disable Metrics/BlockLength
  task :prevent_disparate_pg_dump_versions => :environment do
    allowed_pg_dump_version = '10.6'.freeze

    `pg_dump --version`
    pg_dump_exit_status = $CHILD_STATUS.exitstatus

    locally_installed_version = `pg_dump --version`.chomp[/(\d.*)/,1] rescue nil

    if locally_installed_version != allowed_pg_dump_version
      puts <<~OUTPUT_BLOCK
        Required pg_dump version: #{allowed_pg_dump_version}
        Your version: #{locally_installed_version}
        ---
        Linux upgrade command: `sudo apt-get update && sudo apt-get upgrade`
        OS X upgrade command: `brew upgrade postgresql@10`
        You may also need to tell OS X how to use your Homebrew version of postgres.
        To do this, run `brew info postgresql@10`. There will be a command output that tells you
        how to add it to your path. Follow those instructions.
        ---
      OUTPUT_BLOCK
      raise 'You must update your postgresql-client if you wish to proceed with migrating'
    elsif pg_dump_exit_status == 127
      puts <<~OUTPUT_BLOCK
        System postgres client not installed - it is needed for the db:migrate task.
        ---
        Linux install command:
          `sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"`
          `wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -`
          `sudo apt-get update && sudo apt-get install postgresql-10`
        OS X install command: `brew install postgresql@10`
        ---
      OUTPUT_BLOCK
      raise 'You must install postgresql-client if you wish to proceed with migrating'
    end
  end

  # keep structure.sql in sync with the actual files in the db/migrate folder
  # this minimises the chance of merge conflicts if different branches add migrations
  # since, ideally, migrations will not make it to master in this file unless the corresponding
  # migration actually exists
  task :make_structure_sql_match_db_migrate_folder do
    path = Rails.root.join('db', 'structure.sql')
    double_newline = "\n\n"
    structure_sql_lines = File.read(path).split(double_newline, -1)

    migrations_in_repo = Set.new(Dir.glob('db/migrate/*.rb').map {|p| p.match(/[0-9]+/).try {|m| m[0]}})

    correct_structure_sql_lines = structure_sql_lines.find_all do |line|
      not_a_schema_migration = line.strip.blank? || !line.start_with?("INSERT INTO schema_migrations")

      if not_a_schema_migration
        true
      else
        migration_number = line.match(/[0-9]+/).try {|m| m[0]}
        migration_number && migrations_in_repo.include?(migration_number)
      end
    end.flatten

    File.write(path, correct_structure_sql_lines.join(double_newline))
  end
end

if Rails.env.development? && ENV['PG_DUMP_CHECK']
  # see http://edgar.tumblr.com/post/52300664342/how-to-extend-an-existing-rake-task
  # if you call #enhance with an array it sets it as a prereq (runs before)
  # if you give #enhance a block it adds a behaviour (runs after)
  # see https://github.com/ruby/rake/blob/v10.5.0/lib/rake/task.rb#L100 if you don't believe an API this odd could exist
  #
  # DISABLED for now
  Rake::Task['db:migrate'].enhance ['db:prevent_disparate_pg_dump_versions']
  Rake::Task['db:migrate'].enhance do
    Rake::Task['db:make_structure_sql_match_db_migrate_folder'].invoke
  end
end