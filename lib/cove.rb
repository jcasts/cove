require 'coverage'
require 'zlib'


##
# Cove is a simple Ruby code coverage tool that supports
# reloading and incremental updates.
#
#   result = Cove.run "app/**/*.rb", "lib/**/*.rb" do
#     # run code here
#   end
#
#   new_result = Cove.run "app/**/*.rb" do
#     # run more code here
#   end
#
#   result.merge new_result

class Cove

  # Gem version
  VERSION = '1.0.0'

  require 'cove/ext'
  require 'cove/diff'


  ##
  # Create a new Cove instance with an optional previous Cove results data.

  def initialize prev_data=nil
    @totals  = {}
    @results = {}
  end


  ##
  # Aggregate a Coverage result hash with existing results.

  def add_result name, res
    
  end


  ##
  # Run the given block while measuring coverage.
  # Results will be aggregated to any previous results.

  def run name, &block
    with_reloading do
      begin
        Coverage.start
        block.call
      ensure
        add_result name, Coverage.result
      end
    end
  end


  ##
  # Replace the Kernel.require method with a Kernel.load
  # equivalent.

  def with_reloading &block
    Cove::Ext.use_reload
    block.call
  ensure
    Cove::Ext.use_require
  end
end
