require './ci/common'

namespace :ci do
  namespace :etcd do |flavor|
    task :before_install => ['ci:common:before_install']

    task :install => ['ci:common:install'] do
      sh %(curl -s -L -o $VOLATILE_DIR/etcd.tar.gz\
            https://github.com/coreos/etcd/releases/download/v2.0.3/etcd-v2.0.3-linux-amd64.tar.gz)
      sh %(mkdir $VOLATILE_DIR/etcd)
      sh %(tar xzvf $VOLATILE_DIR/etcd.tar.gz\
                    -C $VOLATILE_DIR/etcd\
                    --strip-components=1 >/dev/null)
    end

    task :before_script => ['ci:common:before_script'] do
      sh %(cd $VOLATILE_DIR/etcd && ./etcd >/dev/null &)
      sleep_for 10
    end

    task :script => ['ci:common:script'] do
      this_provides = [
        'etcd'
      ]
      Rake::Task['ci:common:run_tests'].invoke(this_provides)
    end

    task :cleanup => ['ci:common:cleanup'] do
      sh %(rm -rf $VOLATILE_DIR/etcd* || echo 'etcd not running')
    end

    task :execute do
      exception = nil
      begin
        %w(before_install install before_script script).each do |t|
          Rake::Task["#{flavor.scope.path}:#{t}"].invoke
        end
      rescue => e
        exception = e
        puts "Failed task: #{e.class} #{e.message}".red
      end
      if ENV['SKIP_CLEANUP']
        puts 'Skipping cleanup, disposable environments are great'.yellow
      else
        puts 'Cleaning up'
        Rake::Task["#{flavor.scope.path}:cleanup"].invoke
      end
      fail exception if exception
    end
  end
end
