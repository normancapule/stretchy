require 'spec_helper'

describe Stretchy::Clauses::MatchClause do

  let(:base) { Stretchy::Builders::ShellBuilder.new }
  let(:match_builder) { Stretchy::Builders::MatchBuilder }
  subject { described_class.new(base) }

  it 'creates a temporary instance' do
    expect(described_class.tmp).to be_a(described_class)
  end

  context 'initializes with' do
    specify 'nil' do
      instance = described_class.new(base)
      expect(instance.inverse?).to eq(false)
      expect(instance.should?).to eq(false)
    end

    specify 'string' do
      expect_any_instance_of(match_builder).to receive(:add_matches).with(
        '_all', 'match string',
        inverse: false,
        should: false
      )
      described_class.new(base, 'match string')
    end

    specify 'options' do
      expect_any_instance_of(match_builder).to receive(:add_matches).with(
        :field_one, 'one',
        inverse: false,
        should: false
      )

      expect_any_instance_of(match_builder).to receive(:add_matches).with(
        :field_two, 'two',
        inverse: false,
        should: false
      )
      instance = described_class.new(base, field_one: 'one', field_two: 'two')
    end
  end

  it 'inverts via not' do
    expect(subject.not).to be_a(described_class)
    expect(subject.not.inverse?).to eq(true)
  end

  it 'switches via should' do
    expect(subject.should.should?).to eq(true)
  end

  it 'initializes inverse via string' do
    match_string = 'not matching string'
    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      '_all', match_string,
      inverse: true,
      should: false
    )
    instance = subject.not(match_string)
    expect(instance).to be_a(described_class)
    expect(instance.inverse?).to eq(true)
  end

  it 'initializes inverse with options' do
    match_hash = {string_field: 'not matching string'}
    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      :string_field, match_hash[:string_field],
      inverse: true,
      should: false
    )
    instance = subject.not(match_hash)
    expect(instance).to be_a(described_class)
    expect(instance.inverse?).to eq(true)
  end

  it 'chains not options' do
    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      :field_one, 'one',
      inverse: true,
      should: false
    )

    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      '_all', 'match all',
      inverse: false,
      should: false
    )
    subject.not(field_one: 'one').match('match all')
  end

  it 'chains should options' do
    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      :field_one, 'one',
      inverse: false,
      should: true
    )

    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      '_all', 'match all',
      inverse: false,
      should: false
    )
    subject.should(field_one: 'one').match('match all')
  end

  it 'chains should and not options' do
    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      :field_one, 'one',
      inverse: true,
      should: true
    )

    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      :field_two, 'two',
      inverse: false,
      should: true
    )
    subject.should.not(field_one: 'one').should(field_two: 'two')
  end

  it 'chains should and match options' do
    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      :field_one, 'one',
      inverse: false,
      should: true
    )

    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      :field_two, 'two',
      inverse: true,
      should: true
    )

    expect_any_instance_of(match_builder).to receive(:add_matches).with(
      '_all', 'match all',
      inverse: false,
      should: false
    )

    subject.should(field_one: 'one').not(field_two: 'two').match('match all')
  end

  it 'builds a query filter boost' do
    boost = described_class.new(base, 'match all string').to_boost
    expect(boost).to be_a(Stretchy::Boosts::FilterBoost)
  end

end