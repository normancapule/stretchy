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
    check subject.boost.filter(term: {url_slug: found['url_slug']}, weight: 10)
  end

  specify 'query' do
    check subject.boost.query(match: {_all: found['name']}, weight: 10)
  end

  specify 'where' do
    check subject.boost.where(url_slug: found['url_slug'])
  end

  specify 'match' do
    check subject.boost.match(_all: found['name'])
  end

  describe 'field value' do
    specify 'with only field' do
      check subject.boost.field_value(field: :salary)
    end

    specify 'with field value options' do
      check subject.boost.field_value(
        field:    :salary,
        factor:   1.2,
        modifier: :square
      )
    end

    specify 'with weight' do
      check subject.boost.field_value(
        field:  :salary,
        factor: 1.2,
        weight: 100
      )
    end
  end

  describe 'random value' do
    # fortunately, 'random' has a seed
    specify 'by seed' do
      check subject.boost.random(found['id'])
    end

    specify 'with weight' do
      check subject.boost.random(seed: found['id'], weight: 100)
    end
  end

  specify 'distance from value' do
    check subject.boost.near(
      decay_function: :gauss,
      field: :coords,
      origin: found['coords'],
      scale: '2mi',
      weight: 3
    )
  end

  specify 'not filter' do
    check subject.boost.where.not(url_slug: not_found['url_slug'])
  end

  specify 'not matching' do
    check subject.boost.match.not(name: not_found['name'])
  end

  describe 'function_score options' do
    specify 'from boost' do
      q = subject.boost(score_mode: :min)
        .boost.match(_all: 'game', weight: 2)
        .boost.match(_all: 'video', weight: 1000)
      expect(q.scores.all?{|k,s| s < 1000}).to eq(true)
    end

    specify 'within boost' do
      q = subject.boost.match(_all: 'game', weight: 2, score_mode: :min)
        .boost.match(_all: 'video', weight: 1000)
      expect(q.scores.all?{|k,s| s < 1000}).to eq(true)
    end
  end

end
