class Hotwire::Spark::Installer
  def initialize(application)
    @application = application
  end

  def install
    configure_cable_server
    configure_middleware
    monitor_paths
  end

  private
    attr_reader :application
    delegate :middleware, to: :application

    def configure_cable_server
      application.routes.prepend do
        mount Hotwire::Spark.cable_server => "/hotwire-spark", internal: true, anchor: true
      end
    end

    def configure_middleware
      middleware.use Hotwire::Spark::Middleware
    end

    def monitor_paths
      register_monitored_paths
      file_watcher.start
    end

    def register_monitored_paths
      monitor :css_paths, action: :reload_css
      monitor :html_paths, action: :reload_html
      monitor :stimulus_paths, action: :reload_stimulus
    end

    def monitor(paths_name, action:)
      file_watcher.monitor Hotwire::Spark.public_send(paths_name) do |file_path|
        broadcast_reload_action(action, file_path)
      end
    end

    def broadcast_reload_action(action, file_path)
      Hotwire::Spark.cable_server.broadcast "hotwire_spark", reload_message_for(action, file_path)
    end

    def reload_message_for(action, file_path)
      { action: action, path: file_path }
    end

    def file_watcher
      @file_watches ||= Hotwire::Spark::FileWatcher.new
    end
end
