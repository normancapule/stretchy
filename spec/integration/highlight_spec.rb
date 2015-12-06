require 'spec_helper'

describe 'Highlights' do
  let(:found) { fixture(:sakurai) }
  let(:not_found) { fixture(:mizuguchi) }
  let(:extra) { fixture(:suda) }
  let(:first_name) { found['name'].split(' ').first }
  let(:api) do
    Stretchy.query(index: SPEC_INDEX, type: FIXTURE_TYPE)
      .match(name: first_name)
      .highlight(fields: { name: {} })
  end

  subject { api.results.first['highlight'] }

  it 'returns results with highlights' do
    expect(subject).to be_a Hash
    expect(subject['name']).to include(/#{first_name}/)
  end
end
