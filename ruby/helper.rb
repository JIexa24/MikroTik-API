
module TryCatchMTik
  def self.try_catch (error, *additional_error_array)
    _repeat = false
    _repeat_count = 0
    while (!_repeat)
      begin
        yield if block_given?
        _repeat = true
      rescue error, additional_error_array => v
        _repeat = false
        _repeat_count = _repeat_count + 1
      end
      break if _repeat_count >= 10
    end
  end
end
