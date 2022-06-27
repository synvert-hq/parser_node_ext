# frozen_string_literal: true

require_relative "parser_node_ext/version"

require 'parser'

module ParserNodeExt
  class Error < StandardError; end

  class MethodNotSupported < StandardError; end
  # Your code goes here...

  TYPE_CHILDREN = {
    and: %i[left_value right_value],
    arg: %i[name],
    begin: %i[body],
    block: %i[caller arguments body],
    blockarg: %i[name],
    const: %i[parent_const name],
    class: %i[name parent_class body],
    csend: %i[receiver message arguments],
    cvasgn: %i[left_value right_value],
    cvar: %i[name],
    def: %i[name arguments body],
    definded?: %i[arguments],
    defs: %i[self name arguments body],
    hash: %i[pairs],
    ivasgn: %i[left_value right_value],
    ivar: %i[name],
    lvar: %i[name],
    lvasgn: %i[left_value right_value],
    masgn: %i[left_value right_value],
    module: %i[name body],
    or: %i[left_value right_value],
    or_asgn: %i[left_value right_value],
    pair: %i[key value],
    restarg: %i[name],
    send: %i[receiver message arguments],
    super: %i[arguments],
    zsuper: %i[]
  }

  def self.included(base)
    base.class_eval do
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

      # Get the sibling nodes.
      # @return [Array<Parser::AST::Node>] sibling nodes.
      def siblings
        index = parent.children.index(self)
        parent.children[index + 1..]
      end

      # Dyamically defined method
      # caller, key, left_value, message, name, pairs, parent_class, parent_const, receivr, rgith_value and value.
      # based on const TYPE_CHILDREN.
      %i[
        caller
        key
        left_value
        message
        name
        pairs
        parent_class
        parent_const
        receiver
        right_value
        value
      ].each do |method_name|
        define_method(method_name) do
          index = TYPE_CHILDREN[type]&.index(method_name)
          return children[index] if index

          raise Synvert::Core::MethodNotSupported, "#{method_name} is not handled for #{debug_info}"
        end
      end

      # Return the left value of node.
      # It supports :and, :cvagn, :lvasgn, :masgn, :or and :or_asgn nodes.
      # @example
      #   node # s(:or_asgn, s(:lvasgn, :a), s(:int, 1))
      #   node.left_value # :a
      # @return [Parser::AST::Node] left value of node.
      # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
      def left_value
        return children[0].children[0] if type == :or_asgn

        index = TYPE_CHILDREN[type]&.index(:left_value)
        return children[index] if index

        raise Synvert::Core::MethodNotSupported, "#{left_value} is not handled for #{debug_info}"
      end

      # Get arguments of node.
      # It supports :block, :csend, :def, :defined?, :defs and :send nodes.
      # @example
      #   node # s(:send, s(:const, nil, :FactoryGirl), :create, s(:sym, :post), s(:hash, s(:pair, s(:sym, :title), s(:str, "post"))))
      #   node.arguments # [s(:sym, :post), s(:hash, s(:pair, s(:sym, :title), s(:str, "post")))]
      # @return [Array<Parser::AST::Node>] arguments of node.
      # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
      def arguments
        case type
        when :def, :block
          children[1].children
        when :defs
          children[2].children
        when :send, :csend
          children[2..-1]
        when :defined?
          children
        else
          raise Synvert::Core::MethodNotSupported, "arguments is not handled for #{debug_info}"
        end
      end

      # Get body of node.
      # It supports :begin, :block, :class, :def, :defs and :module node.
      # @example
      #   node # s(:block, s(:send, s(:const, nil, :RSpec), :configure), s(:args, s(:arg, :config)), s(:send, nil, :include, s(:const, s(:const, nil, :EmailSpec), :Helpers)))
      #   node.body # [s(:send, nil, :include, s(:const, s(:const, nil, :EmailSpec), :Helpers))]
      # @return [Array<Parser::AST::Node>] body of node.
      # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
      def body
        case type
        when :begin
          children
        when :def, :block, :class, :module
          return [] if children[2].nil?

          :begin == children[2].type ? children[2].body : children[2..-1]
        when :defs
          return [] if children[3].nil?

          :begin == children[3].type ? children[3].body : children[3..-1]
        else
          raise Synvert::Core::MethodNotSupported, "body is not handled for #{debug_info}"
        end
      end

      # Get condition of node.
      # It supports :if node.
      # @example
      #   node # s(:if, s(:defined?, s(:const, nil, :Bundler)), nil, nil)
      #   node.condition # s(:defined?, s(:const, nil, :Bundler))
      # @return [Parser::AST::Node] condition of node.
      # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
      def condition
        if :if == type
          children[0]
        else
          raise Synvert::Core::MethodNotSupported, "condition is not handled for #{debug_info}"
        end
      end

      # Get keys of :hash node.
      # @example
      #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar")))
      #   node.keys # [s(:sym, :foo), s(:str, "foo")]
      # @return [Array<Parser::AST::Node>] keys of node.
      # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
      def keys
        if :hash == type
          children.map { |child| child.children[0] }
        else
          raise Synvert::Core::MethodNotSupported, "keys is not handled for #{debug_info}"
        end
      end

      # Get values of :hash node.
      # @example
      #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar")))
      #   node.values # [s(:sym, :bar), s(:str, "bar")]
      # @return [Array<Parser::AST::Node>] values of node.
      # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
      def values
        if :hash == type
          children.map { |child| child.children[1] }
        else
          raise Synvert::Core::MethodNotSupported, "keys is not handled for #{debug_info}"
        end
      end

      # Return the exact value of node.
      # It supports :array, :begin, :erange, :false, :float, :irange, :int, :str, :sym and :true nodes.
      # @example
      #   node # s(:array, s(:str, "str"), s(:sym, :str))
      #   node.to_value # ['str', :str]
      # @return [Object] exact value.
      # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
      def to_value
        case type
        when :int, :float, :str, :sym
          children.last
        when :true
          true
        when :false
          false
        when :nil
          nil
        when :array
          children.map(&:to_value)
        when :irange
          (children.first.to_value..children.last.to_value)
        when :erange
          (children.first.to_value...children.last.to_value)
        when :begin
          children.first.to_value
        else
          self
        end
      end

      # Get the source code of node.
      #
      # @return [String] source code.
      def to_source
        loc.expression&.source
      end
    end
  end
end

# Extend Parser::AST::Node.
# {https://github.com/whitequark/parser/blob/master/lib/parser/ast/node.rb}
#
# Rules
#
# Synvert compares ast nodes with key / value pairs, each ast node has
# multiple attributes, e.g. +receiver+, +message+ and +arguments+, it
# matches only when all of key / value pairs match.
#
# +type: 'send', message: :include, arguments: ['FactoryGirl::Syntax::Methods']+
#
# Synvert does comparison based on the value type
#
# 1. if value is a symbol, then compares ast node value as symbol, e.g. +message: :include+
# 2. if value is a string, then compares ast node original source code, e.g. +name: 'Synvert::Application'+
# 3. if value is a regexp, then compares ast node original source code, e.g. +message: /find_all_by_/+
# 4. if value is an array, then compares each ast node, e.g. +arguments: ['FactoryGirl::Syntax::Methods']+
# 5. if value is nil, then check if ast node is nil, e.g. +arguments: [nil]+
# 6. if value is true or false, then check if ast node is :true or :false, e.g. +arguments: [false]+
# 7. if value is ast, then compare ast node directly, e.g. +to_ast: Parser::CurrentRuby.parse("self.class.serialized_attributes")+
#
# It can also compare nested key / value pairs, like
#
# +type: 'send', receiver: { type: 'send', receiver: { type: 'send', message: 'config' }, message: 'active_record' }, message: 'identity_map='+
#
# Source Code to Ast Node
# {https://synvert-playground.xinminlabs.com/ruby}
class Parser::AST::Node
  include ParserNodeExt
end
