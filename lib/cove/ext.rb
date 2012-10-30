##
# This is where evil black magic happens to keep
# the Coverage module happily going when running it
# multiple times in a single Ruby process.

module Cove::Ext
  # Points to original Object#require
  REQUIRE_METHOD = ::Object.instance_method(:require)

  # Force-reload version of Object#require
  RELOAD_METHOD  = Proc.new do |lib|
    return true if REQUIRE_METHOD.call(lib)

    filename = (lib =~ /\.(rb|so)$/) ? lib.dup : "#{lib}.rb"
    retried = false

    begin
      load filename
    rescue LoadError
      filename.sub!(/\.rb$/, '.so')
      unless retried
        retried = true
        retry
      end

      raise LoadError, "cannot load such file -- #{lib}"
    end
  end


  # Mutex for reload usage counter.
  RELOAD_MUTEX = Mutex.new

  @@counter = 0

  def self.use_reload
    Object.__send__(:define_method, :require, &RELOAD_METHOD)
    RELOAD_MUTEX.synchronize{ @@counter += 1 }
  end


  def self.use_require
    Object.__send__(:define_method, :require, &REQUIRE_METHOD)
    RELOAD_MUTEX.synchronize{ @@counter -= 1 }
  end
end
