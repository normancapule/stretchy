require 'spec_helper'

module Stretchy
  describe Utils do

    context 'consumer class' do
      class UtilityConsumer
        include Utils::Methods
      end

      subject { UtilityConsumer.new }

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
    end

    context 'module function' do
      subject { Utils }

      it 'can access the #is_empty? method' do
        expect(subject.is_empty?([])).to eq(true)
      end
    end
  end
end
