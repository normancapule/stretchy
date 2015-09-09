require 'spec_helper'

describe 'Filters' do
  let(:found) { fixture(:sakurai) }
  let(:not_found) { fixture(:mizuguchi) }
  let(:extra) { fixture(:suda) }

  subject { Stretchy.query(index: SPEC_INDEX, type: FIXTURE_TYPE) }

  def check(api)
    ids = api.ids
    expect(ids).to include(found['id'])
    expect(ids).to_not include(not_found['id'])

    # filters do not affect document scores, so make sure this
    # is running filters
    scores = api.scores.values
    expect(scores.all?{|s| s == scores.first}).to eq(true)
  end

  specify 'basic filter' do
    check(subject.filter(terms: {id: [found['id'], extra['id']]}))
  end

  specify 'multiple filters' do
    check subject.filter(terms: {id: [found['id'], extra['id']]})
                 .filter(term: {url_slug: found['url_slug']})
  end

  specify 'not filter' do
    check subject.not.filter(term: {id: not_found['id']})
  end

  # these are kind of useless except minimum_should_match
  specify 'should filters' do
    check subject.should.filter(terms: {id: [found['id'], extra['id']]})
                 .should.filter(term: {url_slug: found['url_slug']})
  end

  specify 'query filter' do
    check subject.filter.query(match: {_all: 'Gamecube'})
  end

  describe 'where filters' do
    let(:salary_range) { (found['salary'] - 5000)..(found['salary'] + 5000) }

    specify 'term string' do
      check subject.where(url_slug: found['url_slug'])
    end

    specify 'term symbol' do
      check subject.where(url_slug: found['url_slug'].to_sym)
    end

    specify 'multiple terms' do
      check subject.where(url_slug: [found['url_slug'], 'not-a-slug'])
    end

    specify 'range' do
      check subject.where(salary: salary_range)
    end

    specify 'nil' do
      check subject.where(is_mizuguchi: nil)
    end

    specify 'together' do
      check subject.where(
        url_slug:     found['url_slug'],
        salary:       salary_range,
        is_mizuguchi: nil
      )
    end
  end

  specify 'range filter' do
    check subject.filter.range(salary: {gte: found['salary']})
  end

  specify 'geo distance filter' do
    check subject.geo_distance(
      distance: '1mi',
      coords: [found['coords']['lon'], found['coords']['lat']]
    )
  end

end
