require 'spec_helper'

describe Stretchy::Filters::RangeFilter do

  subject { Stretchy::Filters::RangeFilter }
  let(:field) { 'salary' }
  let(:date_field) { 'first_game' }
  let(:min) { 850000 }
  let(:max) { 950000 }
  let(:one_day) { 60*60*24 }
  let(:min_date) { Time.now - one_day }
  let(:max_date) { Time.now + one_day }

  def get_result(*args)
    subject.new(*args).to_search[:range]
  end

  describe 'returns json for range filter' do
    specify "inclusive range" do
      result = get_result(field, min: min, max: max)
      expect(result[field]).to match({ gte: min, lte: max })
    end

    specify "exclusive range" do
      result = get_result(field, exclusive: true, min: min, max: max)
      expect(result[field]).to match({ gt: min, lt: max })
    end

    specify "exclusive range operators" do
      result = get_result(field, exclusive_min: true, min: min, exclusive_max: max, max: max)
      expect(result[field]).to match({ gt: min, lt: max })
    end

    specify "mixed range operators" do
      result = get_result(field, exclusive_min: min, min: min, max: max)
      expect(result[field]).to match({ gt: min, lte: max })
    end
  end

  it 'accepts dates for min / max' do
    result = get_result(date_field, min: min_date, max: max_date)
    expect(result[date_field][:gte]).to eq(min_date)
    expect(result[date_field][:lte]).to eq(max_date)
  end

  it 'max field is optional' do
    result = get_result(field, min: min)
    expect(result[field][:gte]).to eq(min)
    expect(result[field][:lte]).to be_nil
  end

  it 'min field is optional' do
    result = get_result(field, max: max)
    expect(result[field][:gte]).to be_nil
    expect(result[field][:lte]).to eq(max)
  end

  it 'raises error unless min or max present' do
    expect{subject.new(field)}.to raise_error
  end

  it 'raises error unless min and max are approriate types' do
    expect{subject.new(field, min: 'wat')}.to raise_error
    expect{subject.new(field, max: 'wat')}.to raise_error
  end
end