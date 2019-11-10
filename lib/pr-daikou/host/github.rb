require 'json'
require 'shellwords'
require 'git_clone_url'

module PRDaikou
  module Host
    # For hosting GitHub
    module Github
      module_function

      def create_branch(email, username, new_branch, commit_message)
        `git checkout -b #{new_branch}`
        `git add .`
        `GIT_AUTHOR_NAME=#{username} GIT_AUTHOR_EMAIL=#{email} GIT_COMMITTER_NAME=#{username} GIT_COMMITTER_EMAIL=#{email} git commit -m "#{commit_message}"`
        `git push #{repository_url} #{new_branch}`
      end

      def create_pullrequest(title, description, base_branch, new_branch)
        options = <<~OPTIONS.strip
          -X POST -H "Authorization: token #{ENV['GITHUB_ACCESS_TOKEN']}" \
          --data #{Shellwords.escape({title: title, body: description, head: new_branch, base: base_branch}.to_json)}
        OPTIONS

        response = `curl #{options} https://api.github.com/repos/#{repository_name}/pulls`
        JSON.parse(response)['number']
      end

      def add_labels_to_pullrequest(pullrequest_number, labels)
        options = <<~OPTIONS.strip
          -X POST -H "Authorization: token #{ENV['GITHUB_ACCESS_TOKEN']}" \
          --data #{Shellwords.escape(labels.to_json)}
        OPTIONS

        `curl #{options} https://api.github.com/repos/#{repository_name}/issues/#{pullrequest_number}/labels`
      end

      def repository_url
        "https://#{ENV['GITHUB_ACCESS_TOKEN']}@github.com/#{repository_name}"
      end

      # ==== Examples
      #
      #   repository_name('git@github.com:rvillage/pr-daikou.git')       # rvillage/pr-daikou
      #   repository_name('ssh://git@github.com/rvillage/pr-daikou.git') # rvillage/pr-daikou
      #   repository_name('https://github.com/rvillage/pr-daikou')       # rvillage/pr-daikou
      #   repository_name('git://github.com/rvillage/pr-daikou.git')     # rvillage/pr-daikou
      #
      def repository_name(url = `git config --get remote.origin.url`.strip)
        path = GitCloneUrl.parse(url).path

        if path.start_with? '/'
          path.slice!(0)
        end

        path[0...path.split('.').first.size]
      end
    end
  end
end
