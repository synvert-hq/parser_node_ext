# frozen_string_literal: true

require_relative "parser_node_ext/version"

require 'parser'
require_relative "parser_node_ext/parent_node_ext"

module ParserNodeExt
  class MethodNotSupported < StandardError; end
  # Your code goes here...

  TYPE_CHILDREN = {
    alias: %i[new_name old_name],
    and: %i[left_value right_value],
    and_asgn: %i[variable value],
    arg: %i[name],
    array: %i[elements],
    array_pattern: %i[elements],
    array_pattern_with_tail: %i[elements],
    back_ref: %i[name],
    begin: %i[body],
    block: %i[caller arguments body],
    blockarg: %i[name],
    block_pass: %i[name],
    break: %i[expression],
    case: %i[expression when_statements else_statement],
    case_match: %i[expression in_statements else_statement],
    casgn: %i[parent_const name value],
    cbase: %i[],
    complex: %i[value],
    const: %i[parent_const name],
    class: %i[name parent_class body],
    csend: %i[receiver message arguments],
    cvasgn: %i[variable value],
    cvar: %i[name],
    def: %i[name arguments body],
    defined?: %i[arguments],
    defs: %i[self name arguments body],
    dstr: %i[elements],
    dsym: %i[elements],
    eflipflop: %i[begin end],
    ensure: %i[body ensure_body],
    erange: %i[begin end],
    false: [],
    find_pattern: %i[elements],
    float: %i[value],
    for: %i[variable expression body],
    forward_args: [],
    gvar: %i[name],
    gvasgn: %i[variable value],
    hash: %i[pairs kwsplats],
    hash_pattern: %i[pairs kwsplats],
    if: %i[expression if_statement else_statement],
    iflipflop: %i[begin end],
    if_guard: %i[expression],
    int: %i[value],
    in_pattern: %i[expression guard body],
    irange: %i[begin end],
    ivasgn: %i[variable value],
    ivar: %i[name],
    kwarg: %i[name],
    kwbody: %i[body],
    kwnilarg: [],
    kwoptarg: %i[name value],
    kwrestarg: %i[name],
    kwsplat: %i[name],
    lvar: %i[name],
    lvasgn: %i[variable value],
    masgn: %i[variable value],
    match_as: %i[key value],
    match_nil_pattern: [],
    match_pattern: %i[left_value right_value],
    match_pattern_p: %i[left_value right_value],
    match_rest: %i[variable],
    match_var: %i[name],
    match_with_lvasgn: %i[left_value right_value],
    mlhs: %i[elements],
    module: %i[name body],
    next: %i[expression],
    nil: [],
    nth_ref: %i[name],
    numblock: %i[caller arguments_count body],
    optarg: %i[name value],
    op_asgn: %i[variable operator value],
    or: %i[left_value right_value],
    or_asgn: %i[variable value],
    pair: %i[key value],
    pin: %i[expression],
    postexe: %i[body],
    preexe: %i[body],
    rational: %i[value],
    redo: [],
    regexp: %i[elements options],
    regopt: %i[elements],
    resbody: %i[exceptions variable body],
    rescue: %i[body rescue_bodies else_statement],
    restarg: %i[name],
    retry: [],
    return: %i[expression],
    sclass: %i[name body],
    self: [],
    shadowarg: %i[name],
    send: %i[receiver message arguments],
    splat: %i[name],
    str: %i[value],
    super: %i[arguments],
    sym: %i[value],
    true: [],
    undef: %i[elements],
    unless_guard: %i[expression],
    until: %i[expression body],
    until_post: %i[expression body],
    when: %i[expression body],
    while: %i[expression body],
    while_post: %i[expression body],
    xstr: %i[elements],
    yield: %i[arguments],
    zsuper: []
  }

  def self.included(base)
    base.class_eval do
      # Dyamically defined method based on const TYPE_CHILDREN.
      TYPE_CHILDREN.values.flatten.uniq.each do |method_name|
        define_method(method_name) do
          index = TYPE_CHILDREN[type]&.index(method_name)
          return children[index] if index

          raise MethodNotSupported, "#{method_name} is not supported for #{self}"
        end
      end

      def full_name
        if %i[class module].include?(type)
          if parent&.respond_to?(:full_name)
            "#{parent.full_name}::#{name.to_source}"
          else
            name.to_source
          end
        end
      end

      # Get arguments of node.
      # It supports :block, :csend, :def, :defined?, :defs, :send, :yeild nodes.
      # @example
      #   node # s(:send, s(:const, nil, :FactoryGirl), :create, s(:sym, :post), s(:hash, s(:pair, s(:sym, :title), s(:str, "post"))))
      #   node.arguments # [s(:sym, :post), s(:hash, s(:pair, s(:sym, :title), s(:str, "post")))]
      # @return [Array<Parser::AST::Node>] arguments of node.
      # @raise [MethodNotSupported] if calls on other node.
      def arguments
        case type
        when :def
          children[1].type == :args ? children[1].children : [children[1]]
        when :defs
          children[2].type == :args ? children[2].children : [children[2]]
        when :block
          children[1].children
        when :send, :csend
          children[2..-1]
        when :defined?, :yield
          children
        else
          raise MethodNotSupported, "arguments is not supported for #{self}"
        end
      end

      # Get body of node.
      # It supports :begin, :block, :class, :def, :defs, :ensure, :for, :module, :numblock, resbody, :sclass, :until, :until_post, :while and :while_post node.
      # @example
      #   node # s(:block, s(:send, s(:const, nil, :RSpec), :configure), s(:args, s(:arg, :config)), s(:send, nil, :include, s(:const, s(:const, nil, :EmailSpec), :Helpers)))
      #   node.body # [s(:send, nil, :include, s(:const, s(:const, nil, :EmailSpec), :Helpers))]
      # @return [Array<Parser::AST::Node>] body of node.
      # @raise [MethodNotSupported] if calls on other node.
      def body
        case type
        when :begin, :kwbegin
          children
        when :rescue, :ensure, :preexe, :postexe
          return [] if children[0].nil?

          [:begin, :kwbegin].include?(children[0].type) ? children[0].body : [children[0]]
        when :when, :module, :sclass, :until, :until_post, :while, :while_post
          return [] if children[1].nil?

          [:begin, :kwbegin].include?(children[1].type) ? children[1].body : children[1..-1]
        when :def, :block, :class, :for, :in_pattern, :numblock, :resbody
          return [] if children[2].nil?

          [:begin, :kwbegin].include?(children[2].type) ? children[2].body : children[2..-1]
        when :defs
          return [] if children[3].nil?

          [:begin, :kwbegin].include?(children[3].type) ? children[3].body : children[3..-1]
        else
          raise MethodNotSupported, "body is not supported for #{self}"
        end
      end

      # Get when statements of case node.
      # @return [Array<Parser::AST::Node>] when statements of case node.
      # @raise [MethodNotSupported] if calls on other node.
      def when_statements
        if :case == type
          children[1...-1]
        else
          raise MethodNotSupported, "when_statements is not supported for #{self}"
        end
      end

      # Get rescue bodies of resuce node.
      # @return [Array<Parser::AST::Node>] rescue statements of rescue node.
      # @raise [MethodNotSupported] if calls on other node.
      def rescue_bodies
        if :rescue == type
          children[1...-1]
        else
          raise MethodNotSupported, "rescue_bodies is not supported for #{self}"
        end
      end

      # Get ensure body of ensure node.
      # @return [Array<Parser::AST::Node>] ensure body of ensure node.
      # @raise [MethodNotSupported] if calls on other node.
      def ensure_body
        if :ensure == type
          children[1..-1]
        else
          raise MethodNotSupported, "ensure_body is not supported for #{self}"
        end
      end

      # Get in statements of case_match node.
      # @return [Array<Parser::AST::Node>] in statements of case node.
      # @raise [MethodNotSupported] if calls on other node.
      def in_statements
        if :case_match == type
          children[1...-1]
        else
          raise MethodNotSupported, "in_statements is not supported for #{self}"
        end
      end

      # Get else statement of node.
      # @return [Parser::AST::Node] else statement of node.
      # @raise [MethodNotSupported] if calls on other node.
      def else_statement
        children[-1]
      end

      # Get elements of :array, :array_pattern, :array_pattern_with_tail, :find_pattern, :dstr, :dsym, :xstr, :regopt, :mlhs and :undef node.
      # @return [Array<Parser::AST::Node>] elements of array node.
      # @raise [MethodNotSupported] if calls on other node.
      def elements
        if %i[array array_pattern array_pattern_with_tail find_pattern dstr dsym xstr regopt mlhs undef].include?(type)
          children
        elsif type == :regexp
          children[0...-1]
        else
          raise MethodNotSupported, "elements is not supported for #{self}"
        end
      end

      # Get options of :regexp node.
      # @example
      #   node # s(:regexp, s(:str, "foo"), s(:regopt, :i, :m))
      #   node.options # s(:regopt, :i, :m)
      # @return [Parser::AST::Node] options of regexp node.
      # @raise [MethodNotSupported] if calls on other node.
      def options
        if :regexp == type
          children[-1]
        else
          raise MethodNotSupported, "options is not supported for #{self}"
        end
      end

      # Get exceptions of :resbody node.
      # @example
      #   node # s(:resbody, s(:array, (:const nil :Exception), (:const nil :A)), s(:lvasgn :bar), s(:int 1))
      #   node.exceptions # s(:array, (:const nil :Exception), (:const nil :A))
      # @return [Parser::AST::Node] exceptions of resbody node.
      # @raise [MethodNotSupported] if calls on other node.
      def exceptions
        if :resbody == type
          children[0]
        else
          raise MethodNotSupported, "exceptions is not supported for #{self}"
        end
      end

      # Get pairs of :hash and :hash_pattern node.
      # @example
      #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar")))
      #   node.pairs # [s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar"))]
      # @return [Array<Parser::AST::Node>] pairs of node.
      # @raise [MethodNotSupported] if calls on other node.
      def pairs
        if %i[hash hash_pattern].include?(type)
          children.select { |child| child.type == :pair }
        else
          raise MethodNotSupported, "pairs is not supported for #{self}"
        end
      end

      # Get keys of :hash node.
      # @example
      #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar")))
      #   node.keys # [s(:sym, :foo), s(:str, "foo")]
      # @return [Array<Parser::AST::Node>] keys of node.
      # @raise [MethodNotSupported] if calls on other node.
      def keys
        if %i[hash hash_pattern].include?(type)
          pairs.map(&:key)
        else
          raise MethodNotSupported, "keys is not supported for #{self}"
        end
      end

      # Get values of :hash node.
      # @example
      #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar")))
      #   node.values # [s(:sym, :bar), s(:str, "bar")]
      # @return [Array<Parser::AST::Node>] values of node.
      # @raise [MethodNotSupported] if calls on other node.
      def values
        if %i[hash hash_pattern].include?(type)
          pairs.map(&:value)
        else
          raise MethodNotSupported, "keys is not supported for #{self}"
        end
      end

      # Get kwsplats of :hash and :hash_pattern node.
      # @example
      #   node s(:hash, s(:pair, s(:int, 1), s(:int, 2)), s(:kwsplat, s(:send, nil, :bar)), s(:pair, s(:sym, :baz), s(:int, 3)))
      #   node.pairs # [s(:kwsplat, s(:send, nil, :bar))]
      # @return [Array<Parser::AST::Node>] kwplats of node.
      # @raise [MethodNotSupported] if calls on other node.
      def kwsplats
        if %i[hash hash_pattern].include?(type)
          children.select { |child| child.type == :kwsplat }
        else
          raise MethodNotSupported, "kwsplats is not supported for #{self}"
        end
      end

      # Return the exact value of node.
      # It supports :array, :begin, :erange, :false, :float, :irange, :int, :str, :sym and :true nodes.
      # @example
      #   node # s(:array, s(:str, "str"), s(:sym, :str))
      #   node.to_value # ['str', :str]
      # @return [Object] exact value.
      # @raise [MethodNotSupported] if calls on other node.
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
        when :begin, :kwbegin
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

      # Respond key value and source for hash node, e.g.
      # @example
      #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)))
      #   node.foo_value # :bar
      #   node.foo_source # ":bar"
      def method_missing(method_name, *args, &block)
        if :args == type && children.respond_to?(method_name)
          return children.send(method_name, *args, &block)
        elsif :hash == type && method_name.to_s.end_with?('_pair')
          key = method_name.to_s[0..-6]
          return pairs.find { |pair| pair.key.to_value.to_s == key }
        elsif :hash == type && method_name.to_s.end_with?('_value')
          key = method_name.to_s[0..-7]
          return pairs.find { |pair| pair.key.to_value.to_s == key }&.value
        elsif :hash == type && method_name.to_s.end_with?('_source')
          key = method_name.to_s[0..-8]
          return pairs.find { |pair| pair.key.to_value.to_s == key }&.value&.to_source || ''
        end

        super
      end

      def respond_to_missing?(method_name, *args)
        if :args == type && children.respond_to?(method_name)
          return true
        elsif :hash == type && method_name.to_s.end_with?('_pair')
          key = method_name.to_s[0..-6]
          return !!pairs.find { |pair| pair.key.to_value.to_s == key }
        elsif :hash == type && method_name.to_s.end_with?('_value')
          key = method_name.to_s[0..-7]
          return !!pairs.find { |pair| pair.key.to_value.to_s == key }
        elsif :hash == type && method_name.to_s.end_with?('_source')
          key = method_name.to_s[0..-8]
          return !!pairs.find { |pair| pair.key.to_value.to_s == key }
        end

        super
      end
    end
  end
end

# Extend Parser::AST::Node.
class Parser::AST::Node
  include ParserNodeExt
end
