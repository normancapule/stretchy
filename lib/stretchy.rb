require 'json'
require 'logger'
require 'forwardable'
require 'excon'
require 'elasticsearch'

require 'stretchy/api'
require 'stretchy/collector'
require 'stretchy/factory'
require 'stretchy/node'
require 'stretchy/version'

# {include:file:README.md}

module Stretchy

  module_function

  def client
    @client ||= Elasticsearch::Client.new
  end

  def search(options = {})
    client.search(options)
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest => bre
    msg = bre.message[-150..-1]
    msg << "\n\n"
    msg << JSON.pretty_generate(options)
    raise msg
  end

  def query(options = {})
    API.new(root: options)
  end

end
