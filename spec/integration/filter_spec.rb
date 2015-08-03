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
    scores = api.results.map{|r| r['_score'] }
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

end
