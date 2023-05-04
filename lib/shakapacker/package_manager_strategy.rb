require "shakapacker/mtime_strategy"
require "shakapacker/digest_strategy"

module Shakapacker
  class PackageManagerStrategy
    def self.from_config
      package_manager = Shakapacker.config.package_manager

      case package_manager
      when "yarn"
        Shakapacker::YarnStrategy.new
      when "pnpm"
        Shakapacker::PnpmStrategy.new
      when "npm"
        Shakapacker::NpmStrategy.new
      else
        raise "Unknown package manager '#{package_manager}'. " \
              "Available options are 'yarn', 'pnpm', and 'npm'."
      end
    end
  end
end
