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
      after_save :"store_#{column}!", :"remove_outdated_#{column}!"
      before_save :"write_#{column}_identifier"
      after_destroy :"remove_#{column}!"

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          #{column}_will_change!
          super
        end

        # Remove outdated image if the previous upload had a file stored and the
        # new upload has nothing stored OR stored the file in a different path.
        def remove_outdated_#{column}!
          previous, current = #{column}_change
          if previous.respond_to?(:stored?) && previous.stored?
            current_stored = current.respond_to?(:stored?) && current.stored?
            previous.remove! if !current_stored || previous.store_path != current.store_path
          end
        end
      RUBY
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.extend CarrierWave::ActiveRecord
