require 'spec_helper'

describe 'Boosts' do
  let(:found) { fixture(:sakurai) }
  let(:not_found) { fixture(:mizuguchi) }
  let(:extra) { fixture(:suda) }

  subject { Stretchy.query(index: SPEC_INDEX, type: FIXTURE_TYPE) }

  def check(api)
    expect(api.scores[found['id']]).to be > api.scores[not_found['id']]
  end

  specify 'filter' do
    check subject.boost.where(url_slug: found['url_slug'])
  end

  specify 'query' do
    check subject.boost.match(_all: found['name'])
  end

  specify 'field value' do
    check subject.boost.field_value(field: :salary)
  end

  # fortunately, 'random' has a seed
  specify 'random value' do
    check subject.boost.random(found['id'])
  end

  specify 'distance from value' do
    check subject.boost.near(
      decay_function: :gauss,
      field: :coords,
      origin: found['coords'],
      scale: '2mi'
    )
  end

  specify 'not filter' do
    check subject.boost.where.not(url_slug: not_found['url_slug'])
  end

  specify 'not matching' do
    check subject.boost.match.not(name: not_found['name'])
  end

end
