require "yaml"

module Functions
  def blu(string)
    _blue = "\033[01;34m"
    _default = "\033[00m"
    return "#{_blue}#{string}#{_default}"
  end

  def gre(string)
    _green = "\033[01;32m"
    _default = "\033[00m"
    return "#{_green}#{string}#{_default}"
  end

  def red(string)
    _red = "\033[01;31m"
    _default = "\033[00m"
    return "#{_red}#{string}#{_default}"
  end

  def yel(string)
    _yellow = "\033[01;33m"
    _default = "\033[00m"
    return "#{_yellow}#{string}#{_default}"
  end

  def println(string)
    STDOUT.print("#{string}\n")
  end

  def nothing()
    return 0
  end

  def load_yml(filename)
    _file = nil
    begin
      _file = YAML.load_file(filename)
    rescue Errno::ENOENT => err
      println("#{red("Error")}: File not found! - #{err}.")
      _file = nil
    end
    return _file
  end
end
