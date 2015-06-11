# encoding: utf-8

require 'cliqr/cli/argument_operator_context'

module Cliqr
  # Definition and builder for command context
  module CLI
    # Manages things like arguments and input/output for a command
    #
    # @api private
    class CommandContext
      # Command name
      #
      # @return [String]
      attr_accessor :command

      # Command arguments
      #
      # @return [Array<String>] List of arguments
      attr_accessor :arguments

      # Name of the current action
      #
      # @return [String]
      attr_accessor :action_name

      # Build a instance of command context based on the parsed set of arguments
      #
      # @param [Cliqr::CLI::Config] config The configuration settings for command's action config
      # @param [Cliqr::Parser::ParsedInput] parsed_input Parsed input object
      #
      # @return [Cliqr::CLI::CommandContext]
      def self.build(config, parsed_input)
        CommandContextBuilder.new(config, parsed_input).build
      end

      # Initialize the command context (called by the CommandContextBuilder)
      #
      # @return [Cliqr::CLI::CommandContext]
      def initialize(config, options, arguments)
        @config = config
        @command = config.command
        @arguments = arguments
        @action_name = config.name
        @context = self

        # make option map from array
        @options = Hash[*options.collect { |option| [option.name, option] }.flatten]
      end

      # List of parsed options
      #
      # @return [Array<Cliqr::CLI::CommandOption>]
      def options
        @options.values
      end

      # Get a option by name
      #
      # @param [String] name Name of the option
      #
      # @return [Cliqr::CLI::CommandOption] Instance of CommandOption for option
      def option(name)
        option = @options[name]
        option.nil? ? CommandOption.new([name, nil], nil) : option
      end

      # Check if a option with a specified name has been passed
      #
      # @param [String] name Name of the option
      #
      # @return [Boolean] <tt>true</tt> if the option has a argument value
      def option?(name)
        @options.key?(name)
      end

      # Check whether the current context is based off of a sub-action
      #
      # @return [Boolean] <tt>true</tt> if this context is based off a sub-action
      def action?
        @config.parent?
      end

      # Handle the case when a method is invoked to get an option value
      #
      # @return [Object] Option's value
      def method_missing(name)
        option_name = name.to_s.chomp('?')
        existence_check = name.to_s.end_with?('?')
        existence_check ? option?(option_name) : option(option_name).value \
          if @config.option?(option_name)
      end

      private :initialize
    end

    private

    # Builder for creating a instance of CommandContext from parsed cli arguments
    #
    # @api private
    class CommandContextBuilder
      # Initialize builder for CommandContext
      #
      # @param [Cliqr::CLI::Config] config The configuration settings for command's action config
      # @param [Cliqr::Parser::ParsedInput] parsed_input Parsed and validated command line arguments
      #
      # @return [Cliqr::CLI::CommandContextBuilder]
      def initialize(config, parsed_input)
        @config = config
        @parsed_input = parsed_input
      end

      # Build a new instance of CommandContext
      #
      # @return [Cliqr::CLI::CommandContext] A newly created CommandContext instance
      def build
        option_contexts = @parsed_input.options.map do |option|
          CommandOption.new(option, @config.option(option.first))
        end

        CommandContext.new @config,
                           option_contexts,
                           @parsed_input.arguments
      end
    end

    # A holder class for a command line argument's name and value
    #
    # @api private
    class CommandOption
      # Name of a command line argument option
      #
      # @return [String]
      attr_accessor :name

      # Value for the command line argument's option
      #
      # @return [Object]
      attr_accessor :value

      # Create a new command line option instance
      #
      # @param [Array] option Parsed arguments for creating a command line option
      # @param [Cliqr::CLI::OptionConfig] option_config Option's config settings
      #
      # @return [Cliqr::CLI::CommandContext] A new CommandOption object
      def initialize(option, option_config)
        if option_config.nil?
          @value = option.pop
        else
          @value = run_value_operator(option.pop, option_config.operator)
        end
        @name = option.pop
      end

      private

      # Run the operator for a named attribute for a value
      #
      # @return [Nothing]
      def run_value_operator(value, operator)
        if operator.is_a?(Proc)
          ArgumentOperatorContext.new(value).instance_eval(&operator)
        else
          operator.operate(value)
        end
      end
    end
  end
end
