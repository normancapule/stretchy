require 'spec_helper'

module Stretchy
  describe Utils do

    shared_examples 'utility methods' do
      describe '#is_empty?' do
        specify 'no args' do
          expect(subject.is_empty?).to eq(true)
        end

        specify 'nil' do
          expect(subject.is_empty?(nil)).to eq(true)
        end

        specify 'empty array' do
          expect(subject.is_empty?([])).to eq(true)
        end

        specify 'empty hash' do
          expect(subject.is_empty?({})).to eq(true)
        end

        specify 'empty str' do
          expect(subject.is_empty?('')).to eq(true)
        end

        specify 'array of empty vals' do
          expect(subject.is_empty?([nil, ''])).to eq(true)
        end

        specify 'false' do
          expect(subject.is_empty?(false)).to eq(true)
        end

        specify 'full string' do
          expect(subject.is_empty?('hello')).to eq(false)
        end

        specify 'full array' do
          expect(subject.is_empty?(['hello'])).to eq(false)
        end

        specify 'hash with any keys' do
          expect(subject.is_empty?({is_nil: nil})).to eq(false)
        end

        specify 'zero' do
          expect(subject.is_empty?(0)).to eq(false)
        end

        specify 'true' do
          expect(subject.is_empty?(true)).to eq(false)
        end
      end

      describe '#require_params!' do
        let(:params) { Hash(one: '', three: 'two') }
        it 'raises error when param is empty' do
          expect{
            subject.require_params!(:my_method, params, :one)
          }.to raise_error(Errors::InvalidParamsError)
        end

        it 'raises error when param is missing' do
          expect{
            subject.require_params!(:my_method, params, :two)
          }.to raise_error(Errors::InvalidParamsError)
        end

        it 'does not raise error when param is present' do
          expect{
            subject.require_params!(:my_method, params, :three)
          }.not_to raise_error
        end
      end

      describe '#extract_options!' do
        let(:input) { Hash(one: 1, two: 2, three: 3) }
        let(:output) { Hash(one: 1) }

        it 'returns existing options' do
          expect(subject.extract_options!(input, [:one])).to eq(output)
          expect(input).not_to include(output)
        end
      end

      describe '#current_page' do
        let(:page) { 2 }
        let(:offset) { 19 }
        let(:limit) { 10 }

        it 'calculates page from inputs' do
          expect(subject.current_page(offset, limit)).to eq page
        end
      end

      describe '#coerce_id' do
        it 'coerces int ids' do
          expect(subject.coerce_id('3')).to eq 3
        end

        it 'leaves others unaffected' do
          expect(subject.coerce_id('4three')).to eq '4three'
        end
      end

      describe 'nested transformations' do
        let(:input) { Hash(
          one: 1,
          parent: {
            child: 'leaf',
            sub: {granchild: 'gc'}
          }
        )}

        describe '#dotify' do
          let(:output) { Hash(
            'one' => 1,
            'parent.child' => 'leaf',
            'parent.sub.granchild' => 'gc'
          )}

          it 'turns hash into dot notation' do
            expect(subject.dotify(input)).to eq(output)
          end
        end

        describe '#nestify' do
          let(:output) {Hash(
            'one' => 1,
            'parent' => {
              'parent.child' => 'leaf',
              'parent.sub' => {
                'parent.sub.granchild' => 'gc'
              }
            }
          )}

          it 'turns hash into nested dot notation' do
            expect(subject.nestify(input)).to eq(output)
          end
        end
      end
    end

    context 'consumer class' do
      class UtilityConsumer
        include Utils::Methods
      end

      subject { UtilityConsumer.new }

      include_examples 'utility methods'
    end

    context 'module function' do
      subject { Utils }

      include_examples 'utility methods'
    end
  end
end
