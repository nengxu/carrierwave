# encoding: utf-8

require 'active_record'
require 'carrierwave/validations/active_model'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute
      public :read_uploader
      public :write_uploader

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

      # Use symbols because strings are evaluated instead of dispatched
      after_save :"store_#{column}!"
      before_save :"write_#{column}_identifier"
      before_update :"store_outdated_#{column}"
      after_update :"remove_outdated_#{column}!"
      after_destroy :"remove_#{column}!"

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          #{column}_will_change!
          super
        end

        private

        def store_outdated_#{column}
          return unless #{column}_changed?
          @cached_uploaders ||= {}
          @cached_uploaders[:#{column}] = self.class.find(to_key[0]).#{column}
        end
      RUBY
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.extend CarrierWave::ActiveRecord
