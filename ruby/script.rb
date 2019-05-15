#!/usr/bin/env ruby
require_relative "functions.rb"
require_relative "helper.rb"
require 'net/ssh'
require 'rubygems'
require 'mtik'

#IP-address config file (ip.yml)
$ip_config_filename_g = "none"
$mail_config_filename_g = "mail_config"

#Users functions

MTik::verbose = true

class MikroTik
  include Functions
  public
    def initialize
      @ip_config = nil
      @mail_config = nil
      @ip_config_filename = $ip_config_filename_g
      @mail_config_filename = $mail_config_filename_g
      @command = ""
      @login = "adm"
      @password = ""
      @email = "example@example.com"
      @email_to = "example@example.com"
      @email_from = "example@example.com"
      @email_server = "0.0.0.0"
      @email_server_name = ""
      @email_pass = "12345"
      @connection = nil
      @connections_failed = []
      @connections_count = 0
      @cmd = nil
      @users = {}
      @groups = {}
      @active_host = ""
      @active_hostname = ""
      @last_backup_time = [["jan","01","1970"],["00","00","00"]]
      @first_connection = false
      @last_connect = {}
      @time_wait = 3
      @configure_server = false
    end

    def run
      println("#{gre("Welcome to MikroTik command-sender. Init complete.")}")
      menu
      while cmdline == true do
        nothing
      end
    end
  private
    def menu
      println("/*------------------------------------*/")
      println("Current login - #{gre(@login)}")
      println("Current password - #{red(@password)}")
      println("Current e-mail - #{gre(@email)}")
      println("Current e-mail server - #{gre(@email_server)}")
      println("Ip_config - #{gre(@ip_config == nil ? "false" : "true")}")
      println(" - m/menu/? - Print menu")
      println(" - u/use - Use ip.yml")
      println(" - s/set [l/login|p/password] - Set login/password for control-user on MikroTik")
      println(" - c/create - Create new user on MikroTik")
      println(" - d/delete - Delete user on MikroTik")
      println(" - cmd/command - Run command on MikroTik (Don't have realisation)")
      println(" - show - Show IP addresses from config")
      println(" - g/get - Get system/users info on devices from config")
      println(" - e/exit - Exit")
    end

    def cmdline
      @cmd = nil
      @connections_failed = []
      @first_connection = false
      @last_connect = {}
      print("#{gre(@login)}\@#{gre(@ip_config_filename)} > ")
      @cmd = gets
      @cmd = @cmd.chomp!.split(' ')
      if @cmd.nil?
        println("#{red("Fatal error!")}")
        exit 1
      end

      case @cmd[0]
        when "s", "set"
          set_login_or_password
        when "g", "get"
          get_data
          print_status
        when "?", "menu", "m"
          menu
        when "u", "use"
          ip_yml
        when "cmd", "command"
          MTik::interactive_client(@active_host, @login, @password) unless @active_host.nil?
          @active_host = nil
        when "show"
          #println @ip_config
          unless @ip_config.nil?
            @ip_config.each_with_index do |v,i|
              println("#{gre(v["name"])} : #{yel(v["ip_or_dns"])}")
              next if v["alt_ip_or_dns"].nil?
              v["alt_ip_or_dns"].each_with_index do |val, ind|
                println("#{gre(v["name"])} : alt - #{yel(val)}")
              end
            end
          end
        when "c", "create"
          create_user
          print_status
        when "d", "delete"
          delete_user
          print_status
        when "e", "exit"
          println("#{gre("Goodbye!")}")
          return false
        when "t", "test"

      end

      return true
    end

    def get_data
        _change = false
        _file = false
        if (!@cmd.index("b").nil? || !@cmd.index("backup").nil?)
          _change = true
          get_backups
        end
        if (!@cmd.index("c").nil? || !@cmd.index("conf").nil?)
          _change = true
          print("#{blu("File?")} > ")
          _file = gets.chomp!.split(' ')[0]
          get_conf _file.eql?("true") ? true : false
        end

        if (!_change)
          print("#{blu("Get?")} > ")
          @cmd[1] = gets.chomp!.split(' ')[0]
          print("#{blu("File?")} > ")
          _file = gets.chomp!.split(' ')[0]
          _file = _file.eql?("true") ? true : false
          get_conf _file if (@cmd[1] == "c" || @cmd[1] == "conf")
          get_backups if (@cmd[1] == "b" || @cmd[1] == "backup")
        end
    end

    def configure_mail_server
      set_mail_config if @mail_config.nil?
      return if @mail_config.nil?
      unless @mail_config.nil?
        if @mail_config[0]["email_to"].nil?
          print("#{blu("E-mail to")} > ")
          @email_to = gets.chomp!.split(' ')[0]
        else
          @email_to = @mail_config[0]["email_to"]
        end
      else
        print("#{blu("E-mail to")} > ")
        @email_to = gets.chomp!.split(' ')[0]
      end
      println("#{yel("E-mail to update!")}")

      unless @mail_config.nil?
        if @mail_config[0]["email_from"].nil?
          print("#{blu("E-mail from")} > ")
          @email_from = gets.chomp!.split(' ')[0]
        else
          @email_from = @mail_config[0]["email_from"]
        end
      else
        print("#{blu("E-mail from")} > ")
        @email_from = gets.chomp!.split(' ')[0]
      end
      println("#{yel("E-mail from update!")}")

      print("#{blu("Configure?")} > ")
      _conf = gets.chomp!.split(' ')[0]
      @configure_server = _conf.eql?("true") ? true : false
      return if @configure_server == false


      unless @mail_config.nil?
        if @mail_config[0]["email_server"].nil?
          print("#{blu("Server")} > ")
          @email_server = gets.chomp!.split(' ')[0]
        else
          @email_server = @mail_config[0]["email_server"]
        end
      else
        print("#{blu("Server")} > ")
        @email_server = gets.chomp!.split(' ')[0]
      end
      println("#{yel("E-mail server update!")}")

      unless @mail_config.nil?
        if @mail_config[0]["email"].nil?
          print("#{blu("E-mail")} > ")
          @email = gets.chomp!.split(' ')[0]
        else
          @email = @mail_config[0]["email"]
        end
      else
        print("#{blu("E-mail")} > ")
        @email = gets.chomp!.split(' ')[0]
      end
      println("#{yel("E-mail update!")}")

      @email_server_name = @email.split("@")[1]

      println("#{yel("E-mail server name: " + @email_server_name)}")
      print("#{blu("E-mail password")} > ")
      @email_pass = gets.chomp!
      println("#{yel("E-mail pass update!")}")
    end

    def get_file_list(type)
      return nil if @connection.nil?
      _list = get_menu(["file", "print"])
      _backup_list = []
      _list.each_with_index do |v, i|
        if v[:type].eql?(type)
          _backup_list << v
        end
      end
      return _backup_list
    end

    def wait_sec(time)
      while time > 0 do
        print("#{gre(".")}")
        time = time - 1
        sleep(1)
      end
      println("")
    end

    def get_backups
      configure_mail_server
      set_ip_config if @ip_config.nil?
      unless @ip_config.nil?
        @ip_config.each_with_index do |v,i|
          _returned_status = connect(v)
          break if _returned_status.equal?(:MTikLoginFailed)
          next if _returned_status.equal?(:MTikConnectionFailed)
          TryCatchMTik::try_catch(MTik::TimeoutError, Errno::ECONNRESET) {
          get_file_list("backup").each_with_index do |v,i|
            @connection.get_reply("/file/remove", "=numbers=#{v[:name]}")
          end
          get_file_list("script").each_with_index do |v,i|
            @connection.get_reply("/file/remove", "=numbers=#{v[:name]}")
          end
          get_sysinfo
          _time = Time.now.to_s.gsub(" ", "_").gsub(":", "-")
          _backup_name = "Backup_"+ @active_hostname.to_s + "_" + @active_host.to_s + "_" + _time
          _export_name = "Export_"+ @active_hostname.to_s + "_" + @active_host.to_s + "_" + _time
          @connection.get_reply("/system/backup/save","=dont-encrypt=yes", "=name=#{_backup_name}")
          wait_sec(@time_wait)
          @connection.send_request(false, "/export", "=file=#{_export_name}")
          wait_sec(@time_wait * 2)
          if @configure_server == true
            @connection.get_reply("/tool/e-mail/set","=address=#{@email_server}", "=from=#{"mikrotik@"+@email_server_name}", "=port=25","=start-tls=yes", "=user=#{@email}", "=password=#{@email_pass}")
            wait_sec(@time_wait)
          end
          if @first_connect.eql?(@active_host)
            @connection.get_reply("/tool/e-mail/send", "=to=#{@email_to}", "=from=#{@email_from}","=subject=#{"Start : " + @sys[:platform] + " " + @sys[:"board-name"] + ":" + @sys[:version] + "@mikrotik." + @active_host.to_s + "_" + @active_hostname.to_s}", "=file=#{_backup_name+".backup" + "," + _export_name+".rsc"}", "=body=#{"Backup/Export\nTime: " + _time}")
#            @connection.get_reply("/tool/e-mail/send", "=to=#{@email_to}", "=from=#{@email_from}","=subject=#{"Start : " + @sys[:platform] + " " + @sys[:"board-name"]+":"+ @sys[:version] + "@mikrotik." + @active_host.to_s + "_" + @active_hostname.to_s}", "=file=#{_backup_name+".backup"}", "=body=#{"Backup\nTime: " + _time}")
          else
            @connection.get_reply("/tool/e-mail/send", "=to=#{@email_to}", "=from=#{@email_from}","=subject=#{@sys[:platform] + " " + @sys[:"board-name"] + ":" + @sys[:version] + "@mikrotik." + @active_host.to_s + "_" + @active_hostname.to_s}", "=file=#{_backup_name+".backup" + "," + _export_name+".rsc"}", "=body=#{"Backup/Export\nTime: " + _time}")
#            @connection.get_reply("/tool/e-mail/send", "=to=#{@email_to}", "=from=#{@email_from}","=subject=#{@sys[:platform] + " " + @sys[:"board-name"] + ":" + @sys[:version] + "@mikrotik." + @active_host.to_s + "_" + @active_hostname.to_s}", "=file=#{_backup_name+".backup"}", "=body=#{"Backup\nTime: " + _time}")
          end
          }
          disconnect
        end
      end
      return if connect(@last_connect).nil?
      _result = ""
      @connections_failed.each_with_index do |v,i|
        _test = ""
        _test.concat(v[0]).concat(":").concat(v[1])
        _result.concat(_test).concat("\n")
      end
      sleep(@time_wait)
      @connection.get_reply("/tool/e-mail/send", "=to=#{@email_to}", "=from=#{@email_from}", "=subject=Statistics", "=body=#{_result}")
      disconnect
    end

    def get_conf file
      _file = false
      if file
        @config_file = open("configuration.conf", "w")
        @config_file.print "Configuration file"
        _file = true
      else
        @config_file = STDOUT
      end
      set_ip_config if @ip_config.nil?
      unless @ip_config.nil?
        @ip_config.each_with_index do |v,i|
          _returned_status = connect(v)
          break if _returned_status.equal?(:MTikLoginFailed)
          next if _returned_status.equal?(:MTikConnectionFailed)
          get_users
          get_sysinfo
          @config_file.print "\r\n\r\n#{v["ip_or_dns"]} : #{@active_hostname}"
          @config_file.print "\r\nUsers:"
          @users.each_with_index do |v, i|
            @config_file.print "\r\n#{v[1][:name]}:#{v[1][:group]}, disabled - #{v[1][:disabled]}"
          end
          @config_file.print "\r\nSystem:"
          @config_file.print "\r\n#{@sys[:platform]}:#{@sys[:"board-name"]}, version - #{@sys[:version]}"
          @config_file.print "\r\nFirmware : Current - #{@sys[:"current-firmware"]}"
          @config_file.print "\r\n           Upgrade - #{@sys[:"upgrade-firmware"]}\n"
          disconnect
        end
      end
      @config_file.close if _file
    end

    def get_users
      return nil if @connection.nil?
      @users = {}
      @groups = {}
      _users = get_menu(["user","print"])
      _groups = get_menu(["user","group","print"])
      _users.each_with_index do |v, i|
        @users[v[:name]] = {}
        v.each_with_index do |val, ind|
          _users = {
            val[0].to_sym => val[1]
          }
          @users[v[:name]].update(_users)
        end
      end
      _groups.each_with_index do |v, i|
        @groups[v[:name]] = {}
        v.each_with_index do |val, ind|
          _users = {
            val[0].to_sym => val[1]
          }
          @groups[v[:name]].update(_users)
        end
      end
    end

    def get_sysinfo
      return nil if @connection.nil?
      @sys = {
        :address   => @active_host
      }
      _sys = get_menu(["system","resource", "print"])
      _sys.each_with_index do |v, i|
        v.each_with_index do |val, ind|
          _sys_tmp = {
            val[0].to_sym => val[1]
          }
          @sys.update(_sys_tmp)
        end
      end
      _sys = get_menu(["system","routerboard", "print"])
      _sys.each_with_index do |v, i|
        v.each_with_index do |val, ind|
          _sys_tmp = {
            val[0].to_sym => val[1]
          }
          @sys.update(_sys_tmp)
        end
      end
    end

    def create_user
      print("#{blu("User name")} > ")
      _user = gets.chomp!.split(' ')[0]
      print("#{blu("User password")} > ")
      _pass = gets.chomp!.split(' ')[0]
      print("#{blu("User group")} > ")
      _group = gets.chomp!.split(' ')[0]

      set_ip_config if @ip_config.nil?
      unless @ip_config.nil?
        @ip_config.each_with_index do |v,i|
          _returned_status = connect(v)
          break if _returned_status.equal?(:MTikLoginFailed)
          next if _returned_status.equal?(:MTikConnectionFailed)
          get_users
          if @groups[_group].nil?
            println("#{red(v["ip_or_dns"])}: Group unavailable!")
          else
            if @users[_user].nil?
              @connection.get_reply("/user/add","=name=#{_user}","=group=#{_group}","=password=#{_pass}","=disabled=false") if !@users.key?(_user)
              println("#{gre(v["ip_or_dns"])}: User #{_user} has been create!")
            else
              println("#{red(v["ip_or_dns"])}: User #{_user} on device!")
            end
          end
          disconnect
        end
      end
    end

    def delete_user
      print("#{blu("User name")} > ")
      _user = gets.chomp!.split(' ')[0]
      set_ip_config if @ip_config.nil?
      unless @ip_config.nil?
        @ip_config.each_with_index do |v,i|
          _returned_status = connect(v)
          break if _returned_status.equal?(:MTikLoginFailed)
          next if _returned_status.equal?(:MTikConnectionFailed)
          get_users
          unless @users[_user].nil?
            @connection.get_reply("/user/remove","=.id=#{@users[_user][:id]}") if @users.key?(_user)
            println("#{gre(v["ip_or_dns"])}: User #{_user} has been remove!")
          else
            println("#{red(v["ip_or_dns"])}: User #{_user} not found on device!")
          end
          disconnect
        end
      end
    end

    def ip_yml
      @ip_config = nil
      if @ip_config.nil?
        print("#{blu("File name(+.yml)")} > ")
        @ip_config_filename = gets.chomp!.split(' ')[0]
        @ip_config_filename.eql?("") ? @ip_config_filename = $ip_config_filename_g : @ip_config_filename = @ip_config_filename
        @ip_config = load_yml("config/#{@ip_config_filename}.yml")
        unless @ip_config.nil?
          println("#{yel("File loaded!")}")
        else
          @ip_config_filename = "none"
        end
      end
    end

    def set_login_or_password
      _change = false
      if (!@cmd.index("p").nil? || !@cmd.index("password").nil?)
        if (!@cmd.index("p").nil?)
          @password = @cmd[@cmd.index("p") + 1]
          _change = true
        else
          @password = @cmd[@cmd.index("password") + 1]
          _change = true
        end
      end
      if (!@cmd.index("l").nil? || !@cmd.index("login").nil?)
        if (!@cmd.index("l").nil?)
          @login = @cmd[@cmd.index("l") + 1]
          _change = true
        else
          @login = @cmd[@cmd.index("login") + 1]
          _change = true
        end
      end

      if (!_change)
        print("#{blu("New login")} > ")
        @login = gets.chomp!.split(' ')[0]
        println("#{yel("Login update!")}")
        print("#{blu("New password")} > ")
        @password = gets.chomp!.split(' ')[0]
        println("#{yel("Password update!")}")
      end
    end


    def connect(host_config)
#      println host_config
      println("#{yel(host_config["ip_or_dns"])}: Connecting...")
      port_knocking host_config, host_config["ip_or_dns"]
      _connection_status = true
      begin
        @connection = MTik::Connection.new(:host => host_config["ip_or_dns"], :user => "#{@login}", :pass => "#{@password}")
      rescue Errno::ETIMEDOUT, Errno::ENETUNREACH, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ECONNRESET, MTik::Error => err
        println("#{red(host_config["ip_or_dns"])}: Connection Error! - #{err}.")
        _connection_status = false
        @connections_failed << [host_config["ip_or_dns"], host_config["name"]]
        return :MTikLoginFailed if err.message.include?("Login failed")
      end
      unless _connection_status
        unless host_config["alt_ip_or_dns"].nil?
          println("#{yel("Trying to connect with alt_ip_or_dns...")}")
          host_config["alt_ip_or_dns"].each_with_index do |v,i|
            println("#{yel(v)}: Connecting...")
            port_knocking host_config, v
            _connection_status = true
            begin
              @connection = MTik::Connection.new(:host => v, :user => "#{@login}", :pass => "#{@password}")
            rescue Errno::ETIMEDOUT, Errno::ENETUNREACH, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ECONNRESET, MTik::Error => err
              println("#{red(v)}: Repeat connection Error! - #{err}.")
              _connection_status = false
              @connections_failed << [v, host_config["name"]]
              return :MTikLoginFailed if err.message.include?("Login failed")
            end
            break if _connection_status
          end
        end
      end
      _connection_status ? @connection = @connection : @connection = nil
      return :MTikConnectionFailed if (@connection.nil?())
      println("#{gre(host_config["ip_or_dns"])}: Connected.")
      @active_host = host_config["ip_or_dns"]
      @first_connect = @active_host unless @first_connection
      @first_connection = true unless @first_connection
      @connection.get_reply_each('/system/identity/print') do |r, s|
        if s.key?('!re')
          @active_hostname = s['name']
        end
      end
      return @active_host
    end

    def disconnect
      return if @connection.nil?
      @connection.close
      @last_connect["ip_or_dns"] = @active_host
      println("#{red(@active_host)}: close connection.")
      @active_host = nil
    end

    def set_active_host
      print("#{blu("Host")} > ")
      _host = gets.chomp!.split(' ')
      @active_host = _host[0]
      @active_host = nil if _host[0].eql?("")
    end

    def port_knocking(host_config, host)
      println("Start port knocking.")
      return if host_config["icmp_port_knock"].nil?
      host_config["icmp_port_knock"].each_with_index do |value, index|
        system "ping -c 1 -s #{value.to_i - 28} #{host}"
        print "#{gre(".")}"
      end
      println("\n#{gre(host)}: Port knocking complete.")
    end

    def get_menu(params)
      _request = ""
      params.each_with_index do |v, i|
        _request += "/#{v}"
      end
      return nil if @connection.nil?
      _reply = []
      @connection.get_reply_each(_request) do |r, s|
        if s.key?('!re')
          _reply << {}
          s.each_with_index do |v, i|
            _reply_tmp = {
              v[0].to_sym => v[1]
            }
            _reply.last.update(_reply_tmp)
          end
        end
      end
      return _reply
    end

    def set_ip_config
      @ip_config = nil
      set_active_host
      @ip_config = Array.new
      @ip_config[0] = Hash.new
      @ip_config[0]["ip_or_dns"] = @active_host
      @ip_config[0]["name"] = "Manual setup"
      @ip_config_filename = @active_host
    end


    def set_mail_config
      @mail_config = nil
      if @mail_config.nil?
        print("#{blu("File name(+.yml)")} > ")
        @mail_config_filename = gets.chomp!.split(' ')[0]
        @mail_config_filename.eql?("") ? @mail_config_filename = $mail_config_filename_g : @mail_config_filename = @mail_config_filename
        @mail_config = load_yml("config/#{@mail_config_filename}.yml")
        unless @mail_config.nil?
          println("#{yel("File loaded!")}")
        else
          @mail_config_filename = "none"
        end
      end
    end

    def print_status
      println("\n#{red("Failed connections")}")
      @connections_failed.each_with_index do |v,i|
        println("#{yel(v[0] + ":" + v[1])}")
      end
    end

    def template

    end
end

MikroTikSender = MikroTik.new
MikroTikSender.run
