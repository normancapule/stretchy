require 'spec_helper'

describe 'Queries' do
  let(:found) { fixture(:sakurai) }
  let(:not_found) { fixture(:mizuguchi) }
  let(:extra) { fixture(:suda) }

  subject { Stretchy.query(index: SPEC_INDEX, type: FIXTURE_TYPE) }

  def check(api)
    ids = api.ids
    expect(ids).to include(found['id'])
    expect(ids).to_not include(not_found['id'])
  end

  it 'runs a basic query' do
    check(subject.query(match: { name: "sakurai"}))
  end

  it 'runs a basic filter' do
    check(subject.query(term: { url_slug: found['url_slug']}))
  end

  it 'runs a not query' do
    check(subject.not.query(term: { url_slug: not_found['url_slug']}))
  end

  it 'runs a should query' do
    q = subject.should.query(match: { name: found['name']})
               .should.query(match: { 'games.platforms' => 'GameCube' })
    sakurai = q.results.find {|r| r['id'] == found['id'] }
    suda    = q.results.find {|r| r['id'] == extra['id'] }

    # .should defaults to "must match at least one filter / query"
    expect(q.ids).to include(found['id'])
    expect(q.ids).to include(extra['id'])
    expect(q.ids).to_not include(not_found['id'])

    # but .should affects the document score - more matchs == higher score
    expect(sakurai['_score']).to be > suda['_score']
  end

end
