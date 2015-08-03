require 'spec_helper'

describe 'Boosts' do
  let(:found) { fixture(:sakurai) }
  let(:not_found) { fixture(:mizuguchi) }
  let(:extra) { fixture(:suda) }

  subject { Stretchy.query(index: SPEC_INDEX, type: FIXTURE_TYPE) }

  def check(api)
    scores = Hash[api.results.map {|r| [r['id'].to_i, r['_score']]}]
    expect(scores[found['id']]).to be > scores[not_found['id']]
  end

  it 'boosts by filter' do
    check subject.boost.where(url_slug: found['url_slug'])
  end

  it 'boosts by query' do
    check subject.boost.match(_all: found['name'])
  end

  it 'boosts by field value' do
    check subject.boost.field_value(field: :salary)
  end

  # fortunately, 'random' has a seed
  it 'boosts by random value' do
    check subject.boost.random(found['id'])
  end

  it 'boosts by distance from value' do
    check subject.boost.near(
      decay_function: :gauss,
      field: :coords,
      origin: found['coords'],
      scale: '2mi'
    )
  end

end
