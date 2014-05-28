require 'spec_helper'

describe 'FactoryGirl.lint' do
  it 'raises when a factory is invalid' do
    define_model 'User', name: :string do
      validates :name, presence: true
    end

    define_model 'AlwaysValid'

    FactoryGirl.define do
      factory :user do
        factory :admin_user
      end

      factory :always_valid
    end

    error_message = <<-ERROR_MESSAGE.strip
The following factories are invalid:

* user
* admin_user
    ERROR_MESSAGE

    expect do
      FactoryGirl.lint
    end.to raise_error FactoryGirl::InvalidFactoryError, error_message
  end

  it 'does not raise when all factories are valid' do
    define_model 'User', name: :string do
      validates :name, presence: true
    end

    FactoryGirl.define do
      factory :user do
        name 'assigned'
      end
    end

    expect { FactoryGirl.lint }.not_to raise_error
  end

  it 'supports models which do not respond to #valid?' do
    define_class 'Thing'

    FactoryGirl.define do
      factory :thing
    end

    expect(Thing.new).not_to respond_to(:valid?)
    expect { FactoryGirl.lint }.not_to raise_error
  end

  context 'selective lint' do

    before do
      define_class 'Wrong' do
        attr_accessor :attr
      end

      define_class 'Right' do
        attr_accessor :attr
      end

      define_class 'FailTest' do
        attr_accessor :attr
      end

      FactoryGirl.define do
        factory :right do
          attr { :success }
        end

        factory :fail_test do
          # this factory is needed for 'only + except' example
          # kinda awkward though
          attr { raise 'This should not be raised. Ever.' }
        end

        factory :wrong do
          attr { raise 'This factory is wrong' }
        end
      end
    end

    it 'proves our test right' do
      expect { FactoryGirl.lint }.to raise_error RuntimeError, 'This should not be raised. Ever.'
    end

    it 'checks only explicitly declared factories' do
      expect { FactoryGirl.lint(only: [:right]) }.not_to raise_error
    end

    it 'skips explicitly declared factories' do
      expect { FactoryGirl.lint(except: [:wrong, :fail_test]) }.not_to raise_error
    end

    it '"expect" factory list should be ignored if "only" is present' do
      expect { FactoryGirl.lint(except: [:wrong], only: [:wrong]) }.to raise_error(
        RuntimeError, 'This factory is wrong'
      )
    end
  end
end
