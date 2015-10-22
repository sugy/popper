module Popper::Action
  class Base
    @next_action = nil
    @action = nil
    @_config = nil

    def self.run(config, mail, params={})
      set_config(config)
      if action?
        begin
          Popper.log.info "run action #{self.action}"
          next_params = task(config, mail, params)
          Popper.log.info "exit action #{self.action}"
        rescue => e
          Popper.log.warn e
          Popper.log.warn e.backtrace
        end
      end
      next_run(config, mail, next_params)
    end

    def self.next_action(action=nil)
      @next_action = action if action
      @next_action
    end

    def self.action(action=nil)
      @action = action if action
      @action
    end

    def self.next_run(config, mail, params={})
      @next_action.run(config, mail, params) if @next_action
    end

    def self.action?
      config && check_params
    end

    def self.set_config(config)
      @_config = config.send(self.action) if config.respond_to?(self.action)
    end

    def self.config
      @_config
    end

    def self.check_params(config); end
  end
end
