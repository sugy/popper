require 'net/pop'
require 'mail'
module Popper
  class Pop
    def self.run
      begin
        Popper::Sync.synchronized do
          Popper.configure.account.each do |profile|
            uidls = []
            begin
              Popper.log.info "start popper #{profile.name}"
              Net::POP3.start(profile.login.server, profile.login.port || 110, profile.login.user, profile.login.password) do |pop|
                pop.mails.each do |m|
                  uidls << m.uidl

                  next if last_uidl(profile.name).include?(m.uidl)

                  mail = Mail.new(m.mail)
                  if rule = match_rule?(profile, mail)
                    Popper.log.info "match mail #{mail.subject}"
                    Popper::Action::Git.run(profile.rules.send(rule).action, mail) if profile.rules.send(rule).respond_to?(:action)
                  end
                end
              end
              last_uidl(profile.name, uidls)
              Popper.log.info "success popper #{profile.name}"
            rescue => e
              Popper.log.warn e
            end
          end
        end
      rescue Locked
        puts "There will be a running process"
      end
    end


    def self.match_rule?(profile, mail)
      profile.rules.to_h.keys.find do |rule|
        profile.rules.send(rule).condition.to_h.all? do |k,v|
          mail.respond_to?(k) && mail.send(k).to_s.match(/#{v}/)
        end
      end
    end

    def self.last_uidl(account, uidl=nil)
      path = File.join(Dir.home, "popper", ".#{account}.uidl")
      @_uidl ||= {}

      File.write(File.join(path), uidl.join("\n")) if uidl

      @_uidl[account] ||= File.exist?(path) ? File.read(path).split(/\r?\n/) : []
      @_uidl[account]
    end

    def self.prepop
      Popper.configure.account.each do |profile|
        begin
          puts "start prepop #{profile.name}"
          uidls = []
          Net::POP3.start(profile.login.server, profile.login.port || 110, profile.login.user, profile.login.password) do |pop|
            uidls = pop.mails.map(&:uidl)
            last_uidl(
              profile.name,
              uidls
            )
          end
        rescue => e
          puts e
        end
        puts "success prepop #{profile.name} mail count:#{uidls.count}"
      end
    end
  end
end
