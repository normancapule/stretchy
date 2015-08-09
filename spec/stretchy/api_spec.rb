require 'spec_helper'

module Stretchy
  describe API do

    subject { API.new(index: SPEC_INDEX, type: FIXTURE_TYPE) }

    describe 'pagination' do

      it 'sets a limit' do
        expect(subject.limit(10).request[:size]).to eq(10)
        expect(subject.size(10).request[:size]).to eq(10)
      end

      it 'sets an offset' do
        expect(subject.offset(10).request[:from]).to eq(10)
        expect(subject.from(10).request[:from]).to eq(10)
      end

      it 'fetches 0-20 for page 1' do
        request = subject.page(1, per_page: 20).request
        expect(request[:from]).to eq(0)
        expect(request[:size]).to eq(20)
      end

      it 'fetches 21-40 for page 2' do
        request = subject.page(2, per_page: 20).request
        expect(request[:from]).to eq(21)
        expect(request[:size]).to eq(20)
      end

    end

  end
end
