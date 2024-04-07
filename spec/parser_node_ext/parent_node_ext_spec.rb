# frozen_string_literal: true

require 'parser/current'
require 'parser_node_ext/parent_node_ext'

RSpec.describe ParserNodeExt do
  def parse(code)
    Parser::CurrentRuby.parse code
  end

  describe '#parent' do
    it 'gets parent node' do
      node = parse('FactoryBot.create(:user)')
      child_node = node.children.first
      expect(child_node.parent).to eq node
    end
  end
end
