# frozen_string_literal: true

class Parser::AST::Node
  # Initialize a Node.
  #
  # It extends {Parser::AST::Node} and set parent for its child nodes.
  def initialize(type, children = [], properties = {})
    @mutable_attributes = {}
    super
    # children could be nil for s(:array)
    Array(children).each do |child_node|
      if child_node.is_a?(Parser::AST::Node)
        child_node.parent = self
      end
    end
  end

  # Get the parent node.
  # @return [Parser::AST::Node] parent node.
  def parent
    @mutable_attributes[:parent]
  end

  # Set the parent node.
  # @param node [Parser::AST::Node] parent node.
  def parent=(node)
    @mutable_attributes[:parent] = node
  end
end
