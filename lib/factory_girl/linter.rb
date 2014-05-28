module FactoryGirl
  class Linter
    def initialize(options = {})
      @factories = FactoryGirl.factories
      @excluded_factories = options[:except]
      @included_factories = options[:only]

      only! && return if @included_factories
      except! if @excluded_factories
    end

    def lint
      invalid_factories = @factories.select do |factory|
        built_factory = FactoryGirl.build(factory.name)

        if built_factory.respond_to?(:valid?)
          !built_factory.valid?
        end
      end

      if invalid_factories.any?
        error_message = <<-ERROR_MESSAGE.strip
  The following factories are invalid:

#{invalid_factories.map {|factory| "* #{factory.name}" }.join("\n")}
        ERROR_MESSAGE

        raise InvalidFactoryError, error_message
      end
    end

    private

    def except!
      if @excluded_factories
        @factories = FactoryGirl.factories.reject do |factory|
          factory.names.any? do |name|
            @excluded_factories.include? name
          end
        end
      end
    end

    def only!
      if @included_factories
        @factories = FactoryGirl.factories.select do |factory|
          factory.names.any? do |name|
            @included_factories.include? name
          end
        end
      end
    end
  end
end

