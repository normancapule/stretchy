require 'json'
require 'logger'
require 'forwardable'
require 'excon'
require 'elasticsearch'

require 'stretchy/api'
require 'stretchy/and_collector'
require 'stretchy/errors'
require 'stretchy/factory'
require 'stretchy/node'
require 'stretchy/results'
require 'stretchy/utils'
require 'stretchy/version'

# {include:file:README.md}

module Stretchy

  module_function

  def client
    @client ||= Elasticsearch::Client.new
  end

  def client=(client)
    @client = client
  end

  def search(options = {})
    client.search(options)
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest => bre
    msg = bre.message[-150..-1]
    msg << "\n\n"
    msg << JSON.pretty_generate(options)
    raise msg
  end

  def index_exists?(name)
    client.indices.exists? index: name
  end

  def delete_index(name)
    client.indices.delete(index: name) if index_exists? name
  end

  def create_index(name, params = {})
    client.indices.create({index: name}.merge(params)) unless index_exists? name
  end

  def index_document(params = {})
    Utils.require_params!(:index_document, params, :index, :type, :body)

    raise IndexDoesNotExistError.new(
      "index #{params[:index]} does not exist"
    ) unless index_exists? params[:index]

    client.index(params)
  end

  def query(options = {})
    API.new(root: options)
  end

  def method_missing(method, *args, &block)
    if client.respond_to?(method)
      client.send(method, *args, &block)
    else
      super
    end
  end

end
