# frozen_string_literal: true
require 'spec_helper'

require 'fixtures/test_command'

describe Cliqr::ArgumentValidation::Validator do
  it 'does not allow multiple actions at the same level in the same command' do
    cli = Cliqr.interface do
      name 'my-command'
      handler TestCommand

      action 'my-action' do
        handler TestCommand
        arguments :disable
      end

      action 'another-action' do
        handler TestCommand
      end
    end
    expect { cli.execute_internal %w(my-action another-action) }.to(
      raise_error(Cliqr::Error::IllegalArgumentError, 'invalid command argument "another-action"')
    )
  end

  it 'does not allow illegal nesting of actions in a command' do
    cli = Cliqr.interface do
      name 'my-command'
      handler TestCommand

      action 'my-action' do
        handler TestCommand
        option 'test-option'

        action 'third-action' do
          handler TestCommand
          option 'third-option'
        end
      end

      action 'another-action' do
        handler TestCommand
        option 'test-option'
        arguments :disable
      end
    end
    expect { cli.execute_internal %w(another-action third-action) }.to(
      raise_error(Cliqr::Error::IllegalArgumentError, 'invalid command argument "third-action"')
    )
  end
end
