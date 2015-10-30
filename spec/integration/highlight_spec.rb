require 'spec_helper'

describe 'Highlights' do
  let(:found) { fixture(:sakurai) }
  let(:not_found) { fixture(:mizuguchi) }
  let(:extra) { fixture(:suda) }

  subject { Stretchy.query(index: SPEC_INDEX, type: FIXTURE_TYPE)
    .match(found['name']).highlight(fields: {name: {}})
  }

  it 'returns results with highlights' do
    expect(subject.results.first['highlight']).to be_a Hash
  end
end
