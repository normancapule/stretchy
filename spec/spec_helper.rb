$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'stretchy'
require 'awesome_print'
require 'pry'

SPEC_INDEX    = 'stretchy_test'
FIXTURE_TYPE  = 'game_dev'
FIXTURES      = {}

Gem.find_files('**/*.json').each do |path|
  name = File.basename(path, '.json').to_sym
  FIXTURES[name] = JSON.parse(File.read(path))
end

# LOGGER        = Logger.new(STDOUT)
# LOGGER.level  = Logger::DEBUG
MAPPING  = {
  game_dev: {
    properties: {
      coords: { type: :geo_point },
      url_slug: { type: :string, index: :not_analyzed },
      games: { type: :nested, comments: { type: :nested }}
    }
  }
}

RSpec.configure do |config|

  config.before(:suite) do
    Stretchy.delete_index(SPEC_INDEX)
    Stretchy.create_index(SPEC_INDEX, body: {mappings: MAPPING})
    FIXTURES.each do |name, data|
      next if name =~ /stub/
      Stretchy.index_document(
        index:  SPEC_INDEX,
        type:   FIXTURE_TYPE,
        id:     data['id'],
        body:   data
      )
    end
    Stretchy.client.indices.refresh(index: SPEC_INDEX)
  end

end

def fixture(name)
  return FIXTURES[name] if FIXTURES[name]
end
