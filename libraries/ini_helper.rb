module GrafanaCookbook
  module IniHelper
    extend ChefVaultCookbook if Kernel.const_defined?("ChefVaultCookbook")
    def self.format_config(config)
      output = []
      config.each do |section, groups|
        output << config_iterator(section, groups)
      end
      output.join "\n"
    end

    def self.config_iterator(section, groups)
      output = []
      if groups.is_a?(Array)
        groups.each do |grp|
          output << config_iterator(section, grp)
        end
      else
        output << format_section(section)
        groups.each do |key, value|
          output << format_kv(key, value)
        end
      end
      output
    end

    def self.format_section(section)
      "\n[#{section}]" if section
    end

    def self.format_kv(key, value)
      case value
      when Hash
        line = ''
        line << '## ' + value['comment'] + "\n" if value['comment']
        line << '# ' if value['disable']
        line << "#{key} = #{value['value']}"
      else
        "#{key} = #{value}"
      end
    end

    def self.data_bag_item(data_bag_name, data_bag_item, missing_ok=false)
      raw_hash = Chef::DataBagItem.load(data_bag_name, data_bag_item)
      encrypted = raw_hash.detect do |key, value|
        if value.is_a?(Hash)
          value.has_key?("encrypted_data")
        end
      end
      if encrypted
        if Chef::DataBag.load(data_bag_name).key? "#{data_bag_item}_keys"
          chef_vault_item(data_bag_name, data_bag_item)
        else
          secret = Chef::EncryptedDataBagItem.load_secret
          Chef::EncryptedDataBagItem.new(raw_hash, secret)
        end
      else
        raw_hash
      end
    rescue Chef::Exceptions::ValidationFailed,
        Chef::Exceptions::InvalidDataBagPath,
        Net::HTTPServerException => error
      missing_ok ? nil : raise(error)
    end
  end
end
