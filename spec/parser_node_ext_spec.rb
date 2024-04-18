# frozen_string_literal: true

require 'parser/current'

RSpec.describe ParserNodeExt do
  def parse(code)
    Parser::CurrentRuby.parse code
  end

  describe '#variable' do
    it 'gets for masgn' do
      node = parse('a, b = 1, 2')
      expect(node.variable.type).to eq :mlhs
    end

    it 'gets for lvasgn' do
      node = parse('a = 1')
      expect(node.variable).to eq :a
    end

    it 'gets for ivasgn' do
      node = parse('@a = 1')
      expect(node.variable).to eq :@a
    end

    it 'gets for cvasgn' do
      node = parse('@@a = 1')
      expect(node.variable).to eq :@@a
    end

    it 'gets for gvasgn' do
      node = parse('$a = 1')
      expect(node.variable).to eq :$a
    end

    it 'gets for op_asgn' do
      node = parse('a += 1')
      expect(node.variable).to eq node.children[0]
    end

    it 'gets for and_asgn' do
      node = parse('a &&= 1')
      expect(node.variable).to eq node.children[0]
    end

    it 'gets for or_asgn' do
      node = parse('a ||= 1')
      expect(node.variable).to eq node.children[0]
    end

    it 'gets for for node' do
      node = parse('for i in 1..10 do; foo; end')
      expect(node.variable).to eq node.children[0]
    end

    it 'gets for resbody node' do
      code = <<~CODE
        begin
          foobar
        rescue Exception, A => bar
          1
        end
      CODE
      node = parse(code).children.first.rescue_bodies.first
      expect(node.variable).to eq node.children[1]
    end

    it 'gets for match_rest node' do
      code = <<~CODE
        expectation = 18
        case [1, 2]
        in ^expectation, *rest
          "matched. expectation was: \#{expectation}"
        else
          "not matched. expectation was: \#{expectation}"
        end
      CODE
      node = parse(code).body[1].in_statements[0].expression.elements[1]
      expect(node.variable.name).to eq :rest
    end
  end

  describe '#begin' do
    it 'gets for iflipflop node' do
      node = parse('if a..b; end').expression
      expect(node.begin).to eq parse('a')
    end

    it 'gets for eflipflop node' do
      node = parse('if a...b; end').expression
      expect(node.begin).to eq parse('a')
    end
  end

  describe '#end' do
    it 'gets for iflipflop node' do
      node = parse('if a..b; end').expression
      expect(node.end).to eq parse('b')
    end

    it 'gets for eflipflop node' do
      node = parse('if a...b; end').expression
      expect(node.end).to eq parse('b')
    end
  end

  describe '#new_name' do
    it 'gets for alias node' do
      node = parse('alias foo bar')
      expect(node.new_name).to eq parse(':foo')
    end
  end

  describe '#old_name' do
    it 'gets for alias node' do
      node = parse('alias foo bar')
      expect(node.old_name).to eq parse(':bar')
    end
  end

  describe '#name' do
    it 'gets for blockpass node' do
      node = parse('object.each(&method(:foo))').arguments.first
      expect(node.name).to eq parse('method(:foo)')
    end

    it 'gets for class node' do
      node = parse('class Synvert; end')
      expect(node.name).to eq parse('Synvert')

      node = parse('class Synvert::Rewriter::Instance; end')
      expect(node.name).to eq parse('Synvert::Rewriter::Instance')
    end

    it 'gets for sclass node' do
      node = parse('class << self; end')
      expect(node.name).to eq parse('self')
    end

    it 'gets for module node' do
      node = parse('module Synvert; end')
      expect(node.name).to eq parse('Synvert')
    end

    it 'gets for def node' do
      node = parse('def current_node; end')
      expect(node.name).to eq :current_node
    end

    it 'gets for defs node' do
      node = parse('def self.current_node; end')
      expect(node.name).to eq :current_node
    end

    it 'gets for arg node' do
      node = parse('def test(foo); end').arguments.first
      expect(node.name).to eq :foo
    end

    it 'gets for blockarg node' do
      node = parse('def test(&block); end').arguments.first
      expect(node.name).to eq :block
    end

    it 'gets for optarg node' do
      node = parse("def test(foo = 'foo'); end").arguments.first
      expect(node.name).to eq :foo
    end

    it 'gets for kwarg node' do
      node = parse("def test(foo:, bar:); end").arguments.first
      expect(node.name).to eq :foo
    end

    it 'gets for kwoptarg node' do
      node = parse("def test(foo: 'foo', bar: 'bar'); end").arguments.first
      expect(node.name).to eq :foo
    end

    it 'gets for kwrestarg node' do
      node = parse("def test(**foo); end").arguments.first
      expect(node.name).to eq :foo
    end

    it 'gets for kwsplat node' do
      node = parse("foo(1 => 2, **bar, baz: 3)").arguments.first.kwsplats[0]
      expect(node.name).to eq parse('bar')
    end

    it 'gets for shadowarg node' do
      node = parse("test { |; foo, bar| }").arguments.first
      expect(node.name).to eq :foo
    end

    it 'gets for const node' do
      node = parse('Synvert')
      expect(node.name).to eq :Synvert
    end

    it 'gets for lvar node' do
      node = parse("foo = 'bar'\nfoo").children[1]
      expect(node.name).to eq :foo
    end

    it 'gets for ivar node' do
      node = parse("@foo = 'bar'\n@foo").children[1]
      expect(node.name).to eq :@foo
    end

    it 'gets for cvar node' do
      node = parse("@@foo = 'bar'\n@@foo").children[1]
      expect(node.name).to eq :@@foo
    end

    it 'gets for gvar node' do
      node = parse('$foo')
      expect(node.name).to eq :$foo
    end

    it 'gets for casgn node' do
      node = parse('::Foo = 1')
      expect(node.name).to eq :Foo
    end

    it 'gets for restarg node' do
      node = parse('object.each { |*entry| }').arguments.first
      expect(node.name).to eq :entry
    end

    it 'gets for splat node' do
      node = parse('test(*foo)').arguments.first
      expect(node.name).to eq parse('foo')
    end

    it 'gets for nth_ref node' do
      node = parse("$1")
      expect(node.name).to eq 1
    end

    it 'gets for back_ref node' do
      node = parse("$&")
      expect(node.name).to eq :$&
    end

    it 'gets for match_var node' do
      code = <<~CODE
        case name_hash
        in {username: username}
          username
        in {first: first, last: last}
          "\#{first} \#{last}"
        else
          'New User'
        end
      CODE
      node = parse(code).in_statements[0].expression.pairs[0].value
      expect(node.name).to eq :username
    end
  end

  describe '#parent_class' do
    it 'gets for class node' do
      node = parse('class Post < ActiveRecord::Base; end')
      expect(node.parent_class).to eq parse('ActiveRecord::Base')
    end
  end

  describe '#receiver' do
    it 'gets for send node' do
      node = parse('FactoryGirl.create :post')
      expect(node.receiver).to eq parse('FactoryGirl')
    end

    it 'gets for csend node' do
      node = parse('user&.update(name: name)')
      expect(node.receiver).to eq parse('user')
    end
  end

  describe '#message' do
    it 'gets for send node' do
      node = parse('FactoryGirl.create :post')
      expect(node.message).to eq :create
    end

    it 'gets for csend node' do
      node = parse('user&.update(name: name)')
      expect(node.message).to eq :update
    end
  end

  describe '#parent_const' do
    it 'gets for const node' do
      node = parse('Synvert::Node')
      expect(node.parent_const).to eq parse('Synvert')
    end

    it 'gets for const node at the root' do
      node = parse('::Node')
      expect(node.parent_const.type).to eq :cbase
    end

    it 'gets for const node with no parent' do
      node = parse('Node')
      expect(node.parent_const).to eq nil
    end

    it 'gets for casgn node' do
      node = parse('::Foo = 1')
      expect(node.parent_const.type).to eq :cbase
    end
  end

  describe '#arguments' do
    it 'gets for def node' do
      node = parse('def test(foo, bar); foo + bar; end')
      expect(node.arguments.map(&:type)).to eq [:arg, :arg]
    end

    it 'gets forward_args for def node' do
      node = parse('def test(...); end')
      expect(node.arguments.map(&:type)).to eq [:forward_args]
    end

    it 'gets for defs node' do
      node = parse('def self.test(foo, bar); foo + bar; end')
      expect(node.arguments.map(&:type)).to eq [:arg, :arg]
    end

    it 'gets forward_args for defs node' do
      node = parse('def self.test(...); end')
      expect(node.arguments.map(&:type)).to eq [:forward_args]
    end

    it 'gets for block node' do
      node = parse('RSpec.configure do |config|; end')
      expect(node.arguments.map(&:type)).to eq [:arg]
    end

    it 'gets for send node' do
      node = parse("FactoryGirl.create :post, title: 'post'")
      expect(node.arguments).to eq parse("[:post, title: 'post']").children
    end

    it 'gets for csend node' do
      node = parse('user&.update(name: name)')
      expect(node.arguments).to eq parse('[name: name]').children
    end

    it 'gets for defined? node' do
      node = parse('defined?(Bundler)')
      expect(node.arguments).to eq [parse('Bundler')]
    end

    it 'gets for yield node' do
      node = parse('yield(foo, bar)')
      expect(node.arguments).to eq [parse('foo'), parse('bar')]
    end
  end

  describe '#arguments_count' do
    it 'gets for numblock node' do
      node = parse('(1..10).each { p _1 * 2 }')
      expect(node.arguments_count).to eq 1
    end
  end

  describe '#caller' do
    it 'gets for block node' do
      node = parse('RSpec.configure do |config|; end')
      expect(node.caller).to eq parse('RSpec.configure')
    end

    it 'gets for numblock node' do
      node = parse('(1..10).each { p _1 * 2 }')
      expect(node.caller).to eq parse('(1..10).each')
    end
  end

  describe '#body' do
    it 'gets one line for block node' do
      node = parse('RSpec.configure do |config|; include EmailSpec::Helpers; end')
      expect(node.body).to eq [parse('include EmailSpec::Helpers')]
    end

    it 'gets multiple lines for block node' do
      node = parse('RSpec.configure do |config|; include EmailSpec::Helpers; include EmailSpec::Matchers; end')
      expect(node.body).to eq [parse('include EmailSpec::Helpers'), parse('include EmailSpec::Matchers')]
    end

    it 'gets for class node' do
      node = parse('class User; def admin?; false; end; end')
      expect(node.body).to eq [parse('def admin?; false; end')]
    end

    it 'gets for sclass node' do
      node = parse('class << self; def admin?; false; end; end')
      expect(node.body).to eq [parse('def admin?; false; end')]
    end

    it 'gets for module node' do
      node = parse('module Admin; def admin?; true; end; end')
      expect(node.body).to eq [parse('def admin?; true; end')]
    end

    it 'gets one line for class node' do
      node = parse('class User; attr_accessor :email; end')
      expect(node.body).to eq [parse('attr_accessor :email')]
    end

    it 'gets one line for class node' do
      node = parse('class User; attr_accessor :email; attr_accessor :username; end')
      expect(node.body).to eq [parse('attr_accessor :email'), parse('attr_accessor :username')]
    end

    it 'gets for begin node' do
      node = parse('foo; bar')
      expect(node.body).to eq [parse('foo'), parse('bar')]
    end

    it 'gets for def node' do
      node = parse('def test; foo; bar; end')
      expect(node.body).to eq [parse('foo'), parse('bar')]
    end

    it 'gets for def node with empty body' do
      node = parse('def test; end')
      expect(node.body).to eq []
    end

    it 'gets for defs node' do
      node = parse('def self.test; foo; bar; end')
      expect(node.body).to eq [parse('foo'), parse('bar')]
    end

    it 'gets for def node with empty body' do
      node = parse('def self.test; end')
      expect(node.body).to eq []
    end

    it 'gets for for node' do
      node = parse('for i in 1..10 do; foo; end')
      expect(node.body).to eq [parse('foo')]
    end

    it 'gets for until node' do
      node = parse('until condition; foo; end')
      expect(node.body).to eq [parse('foo')]
    end

    it 'gets for until_post node' do
      node = parse('begin; foo; end until condition')
      expect(node.body).to eq [parse('foo')]
    end

    it 'gets for while node' do
      node = parse('while condition; foo; end')
      expect(node.body).to eq [parse('foo')]
    end

    it 'gets for while_post node' do
      node = parse('begin; foo; end while condition')
      expect(node.body).to eq [parse('foo')]
    end

    it 'gets for when node' do
      code = <<~CODE
        case expression
        when foo
          'foo'
        when bar
          'bar'
        else
        end
      CODE
      node = parse(code)
      expect(node.when_statements[0].body).to eq [parse("'foo'")]
    end

    it 'gets for rescue node' do
      code = <<~CODE
        begin
          foobar
        rescue Timeout::Error
          'timeout'
        resuce StandardError => e
          e.message
        else
          'else'
        end
      CODE
      node = parse(code).children.first
      expect(node.body).to eq [parse('foobar')]
    end

    it 'gets for resbody node' do
      code = <<~CODE
        begin
          foobar
        rescue Exception, A => bar
          1
        end
      CODE
      node = parse(code).children.first.rescue_bodies.first
      expect(node.body).to eq [parse('1')]
    end

    it 'gets for ensure node' do
      code = <<~CODE
        begin
          foobar
        ensure
          1
        end
      CODE
      node = parse(code).children.first
      expect(node.body).to eq [parse('foobar')]
    end

    it 'gets for in_pattern node' do
      code = <<~CODE
        case name_hash
        in {username: username}
          username
        in {first: first, last: last}
          "\#{first} \#{last}"
        else
          'New User'
        end
      CODE
      node = parse(code).in_statements[0]
      expect(node.body).to eq [node.children[2]]
    end

    it 'gets for numblock node' do
      node = parse('(1..10).each { p _1 * 2 }')
      expect(node.body).to eq [node.children[2]]
    end

    it 'gets for preexe node' do
      node = parse('BEGIN { puts "foo" }')
      expect(node.body).to eq [node.children[0]]
    end

    it 'gets for postexe node' do
      node = parse('END { puts "bar" }')
      expect(node.body).to eq [node.children[0]]
    end
  end

  describe '#rescue_bodies' do
    it 'gets for rescue node' do
      code = <<~CODE
        begin
          foobar
        rescue Timeout::Error
          'timeout'
        rescue StandardError => e
          e.message
        else
          'else'
        end
      CODE
      node = parse(code).children.first
      expect(node.rescue_bodies.size).to eq 2
    end
  end

  describe '#ensure_body' do
    it 'gets for ensure node' do
      code = <<~CODE
        begin
          foobar
        ensure
          1
        end
      CODE
      node = parse(code).children.first
      expect(node.ensure_body).to eq [parse('1')]
    end
  end

  describe '#kwsplats' do
    it 'gets for hash node' do
      node = parse("foo(1 => 2, **bar, baz: 3)").arguments.first
      expect(node.kwsplats).to eq [node.children[1]]
    end
  end

  describe '#pairs' do
    it 'gets for hash node' do
      node = parse("{:foo => :bar, 'foo' => 'bar'}")
      expect(node.pairs).to eq [node.children[0], node.children[1]]
    end

    it 'gets for hash_pattern node' do
      node = parse('http_response in { ok?: true, body?: true, text?: true }').right_value
      expect(node.pairs).to eq [node.children[0], node.children[1], node.children[2]]
    end
  end

  describe '#keys' do
    it 'gets for hash node' do
      node = parse("{:foo => :bar, 'foo' => 'bar'}")
      expect(node.keys).to eq [parse(':foo'), parse("'foo'")]
    end
  end

  describe '#values' do
    it 'gets for hash node' do
      node = parse("{:foo => :bar, 'foo' => 'bar'}")
      expect(node.values).to eq [parse(':bar'), parse("'bar'")]
    end
  end

  describe '#key' do
    it 'gets for pair node' do
      node = parse("{:foo => 'bar'}").children[0]
      expect(node.key).to eq parse(':foo')
    end

    it 'gets for match_as node' do
      code = <<~CODE
        case [1, 2]
        in Integer => a, Integer
          "matched: \#{a}"
        else
          "not matched"
        end
      CODE
      node = parse(code).in_statements[0].expression.elements[0]
      expect(node.key).to eq parse('Integer')
    end
  end

  describe '#value' do
    it 'gets for complex node' do
      node = parse('1i')
      expect(node.value).to eq(0 + 1i)
    end

    it 'gets for rational node' do
      node = parse('2.0r')
      expect(node.value).to eq(2 / 1)
    end

    it 'gets for pair node' do
      node = parse("{:foo => 'bar'}").children[0]
      expect(node.value).to eq parse("'bar'")
    end

    it 'gets for match_as node' do
      code = <<~CODE
        case [1, 2]
        in Integer => a, Integer
          "matched: \#{a}"
        else
          "not matched"
        end
      CODE
      node = parse(code).in_statements[0].expression.elements[0]
      expect(node.value).to eq node.children[1]
      expect(node.value.type).to eq :match_var
    end

    it 'gets for str node' do
      node = parse("'foo'")
      expect(node.value).to eq 'foo'
    end

    it 'gets for sym node' do
      node = parse(':foo')
      expect(node.value).to eq :foo
    end

    it 'gets for int node' do
      node = parse('1')
      expect(node.value).to eq 1
    end

    it 'gets for float node' do
      node = parse('1.1')
      expect(node.value).to eq 1.1
    end

    it 'gets for optarg node' do
      node = parse("def test(foo = 'foo'); end").arguments.first
      expect(node.value).to eq parse("'foo'")
    end

    it 'gets for kwoptarg node' do
      node = parse("def test(foo: 'foo', bar: 'bar'); end").arguments.first
      expect(node.value).to eq parse("'foo'")
    end

    it 'gets for masgn' do
      node = parse('a, b = 1, 2')
      expect(node.value).to eq parse('[1, 2]')
    end

    it 'gets for masgn' do
      node = parse('a, b = params')
      expect(node.value).to eq parse('params')
    end

    it 'gets for lvasgn' do
      node = parse('a = 1')
      expect(node.value).to eq parse('1')
    end

    it 'gets for ivasgn' do
      node = parse('@a = 1')
      expect(node.value).to eq parse('1')
    end

    it 'gets for cvasgn' do
      node = parse('@@a = 1')
      expect(node.value).to eq parse('1')
    end

    it 'gets for gvasgn' do
      node = parse('$a = 1')
      expect(node.value).to eq parse('1')
    end

    it 'gets for op_asgn' do
      node = parse('a += 1')
      expect(node.value).to eq parse('1')
    end

    it 'gets for and_asgn' do
      node = parse('a &&= 1')
      expect(node.value).to eq parse('1')
    end

    it 'gets for or_asgn' do
      node = parse('a ||= 1')
      expect(node.value).to eq parse('1')
    end

    it 'gets for casgn node' do
      node = parse('::Foo = 1')
      expect(node.value).to eq parse('1')
    end
  end

  describe '#hash_pair' do
    it 'gets pair of specified key' do
      node = parse('{:foo => :bar}')
      expect(node.hash_pair(:foo)).to eq node.children[0]
    end

    it 'gets nil if key does not exist' do
      node = parse('{:foo => :bar}')
      expect(node.hash_pair(:bar)).to be_nil
    end
  end

  describe '#hash_value' do
    it 'gets value of specified key' do
      node = parse('{:foo => :bar}')
      expect(node.hash_value(:foo)).to eq parse(':bar')
    end

    it 'gets nil if key does not exist' do
      node = parse('{:foo => :bar}')
      expect(node.hash_value(:bar)).to be_nil
    end
  end

  describe '#left_value' do
    it 'gets for and' do
      node = parse('foo && bar')
      expect(node.left_value).to eq parse('foo')
    end

    it 'gets for or' do
      node = parse('foo || bar')
      expect(node.left_value).to eq parse('foo')
    end

    it 'gets for match_pattern_p' do
      node = parse('http_response in { ok?: true, body?: true, text?: true }')
      expect(node.left_value).to eq parse('http_response')
    end

    it 'gets for match_pattern' do
      node = parse('config => {db: {user:}}')
      expect(node.left_value).to eq parse('config')
    end

    it 'gets for match_with_lvasgn node' do
      node = parse('/(?<match>bar)/ =~ baz')
      expect(node.left_value).to eq node.children[0]
    end
  end

  describe '#right_value' do
    it 'gets for and' do
      node = parse('foo && bar')
      expect(node.right_value).to eq parse('bar')
    end

    it 'gets for or' do
      node = parse('foo || bar')
      expect(node.right_value).to eq parse('bar')
    end

    it 'gets for match_pattern_p' do
      node = parse('http_response in { ok?: true, body?: true, text?: true }')
      expect(node.right_value).to eq node.children[1]
      expect(node.right_value.type).to eq :hash_pattern
    end

    it 'gets for match_pattern' do
      node = parse('config => {db: {user:}}')
      expect(node.right_value).to eq node.children[1]
      expect(node.right_value.type).to eq :hash_pattern
    end

    it 'gets for match_with_lvasgn node' do
      node = parse('/(?<match>bar)/ =~ baz')
      expect(node.right_value).to eq node.children[1]
    end
  end

  describe '#operator' do
    it 'gets for op_asgn' do
      node = parse('a += 1')
      expect(node.operator).to eq :+
    end
  end

  describe '#expression' do
    it 'gets for if node' do
      code = <<~CODE
        if expression
          true
        else
          false
        end
      CODE
      node = parse(code)
      expect(node.expression).to eq parse('expression')
    end

    it 'gets for case node' do
      code = <<~CODE
        case expression
        when foo
          'foo'
        when bar
          'bar'
        else
        end
      CODE
      node = parse(code)
      expect(node.expression).to eq parse('expression')
    end

    it 'gets for case_match node' do
      code = <<~CODE
        case name_hash
        in {username: username}
          username
        in {first: first, last: last}
          "\#{first} \#{last}"
        else
          'New User'
        end
      CODE
      node = parse(code)
      expect(node.expression).to eq parse('name_hash')
    end

    it 'gets for for node' do
      node = parse('for i in 1..10; foo; end')
      expect(node.expression).to eq parse('1..10')
    end

    it 'gets for when node' do
      code = <<~CODE
        case expression
        when foo
          'foo'
        when bar
          'bar'
        else
        end
      CODE
      node = parse(code)
      expect(node.when_statements[0].expression).to eq parse('foo')
    end

    it 'gets for until node' do
      code = <<~CODE
        until condition
          foo
        end
      CODE
      node = parse(code)
      expect(node.expression).to eq parse('condition')
    end

    it 'gets for until_post node' do
      node = parse('begin; foo; end until condition')
      expect(node.expression).to eq parse('condition')
    end

    it 'gets for while node' do
      node = parse('begin; foo; end while condition')
      expect(node.expression).to eq parse('condition')
    end

    it 'gets for in_pattern node' do
      code = <<~CODE
        case name_hash
        in {username: username}
          username
        in {first: first, last: last}
          "\#{first} \#{last}"
        else
          'New User'
        end
      CODE
      node = parse(code).in_statements[0]
      expect(node.expression).to eq node.children[0]
    end

    it 'gets for if_guard node' do
      code = <<~CODE
        case [1, 2]
        in a, b if b == a*2
          "matched"
        else
          "not matched"
        end
      CODE
      node = parse(code).in_statements[0].guard
      expect(node.expression).to eq node.children[0]
    end

    it 'gets for unless_guard node' do
      code = <<~CODE
        case [1, 2]
        in a, b unless b != a*2
          "matched"
        else
          "not matched"
        end
      CODE
      node = parse(code).in_statements[0].guard
      expect(node.expression).to eq node.children[0]
    end

    it 'gets for break node' do
      node = parse('break 1')
      expect(node.expression).to eq parse('1')
    end

    it 'gets for next node' do
      node = parse('next 1')
      expect(node.expression).to eq parse('1')
    end

    it 'gets for return node' do
      node = parse('return 1')
      expect(node.expression).to eq parse('1')
    end

    it 'gets for pin node' do
      code = <<~CODE
        expectation = 18
        case [1, 2]
        in ^expectation, *rest
          "matched. expectation was: \#{expectation}"
        else
          "not matched. expectation was: \#{expectation}"
        end
      CODE
      node = parse(code).body[1].in_statements[0].expression.elements[0]
      expect(node.expression.name).to eq :expectation
    end
  end

  describe '#guard' do
    it 'gets for in_pattern node' do
      code = <<~CODE
        case [1, 2]
        in a, b if b == a*2
          "matched"
        else
          "not matched"
        end
      CODE
      node = parse(code).in_statements[0]
      expect(node.guard).to eq node.children[1]
      expect(node.guard.type).to eq :if_guard
    end
  end

  describe '#if_statement' do
    it 'gets for if node' do
      code = <<~CODE
        if expression
          true
        else
          false
        end
      CODE
      node = parse(code)
      expect(node.if_statement).to eq parse('true')
    end
  end

  describe '#when_statements' do
    it 'gets for case node' do
      code = <<~CODE
        case expression
        when foo
          'foo'
        when bar
          'bar'
        else
        end
      CODE
      node = parse(code)
      expect(node.when_statements).to eq node.children[1..2]
    end
  end

  describe '#in_statements' do
    it 'gets for case_match node' do
      code = <<~CODE
        case name_hash
        in {username: username}
          username
        in {first: first, last: last}
          "\#{first} \#{last}"
        else
          'New User'
        end
      CODE
      node = parse(code)
      expect(node.in_statements).to eq node.children[1..2]
    end
  end

  describe '#else_statment' do
    it 'gets for if node' do
      code = <<~CODE
        if expression
          true
        else
          false
        end
      CODE
      node = parse(code)
      expect(node.else_statement).to eq parse('false')
    end

    it 'gets for rescue node' do
      code = <<~CODE
        begin
          foobar
        rescue Timeout::Error
          'timeout'
        resuce StandardError => e
          e.message
        else
          'else'
        end
      CODE
      node = parse(code).children.first
      expect(node.else_statement).to eq parse("'else'")
    end

    it 'gets for case node' do
      code = <<~CODE
        case expression
        when foo
          'foo'
        when bar
          'bar'
        else
        end
      CODE
      node = parse(code)
      expect(node.else_statement).to be_nil
    end

    it 'gets for case_match node' do
      code = <<~CODE
        case name_hash
        in {username: username}
          username
        in {first: first, last: last}
          "\#{first} \#{last}"
        else
          'New User'
        end
      CODE
      node = parse(code)
      expect(node.else_statement).to eq parse("'New User'")
    end
  end

  describe '#elements' do
    it 'gets for array node' do
      code = "[foo, bar]"
      node = parse(code)
      expect(node.elements).to eq [parse('foo'), parse('bar')]
    end

    it 'gets for array_pattern node' do
      node = parse("user in ['foo', 'bar']").right_value
      expect(node.elements).to eq [parse("'foo'"), parse("'bar'")]
    end

    it 'gets for array_pattern_with_tail node' do
      node = parse("user in ['foo',]").right_value
      expect(node.elements).to eq [parse("'foo'")]
    end

    it 'gets for find_pattern node' do
      code = <<~CODE
        case ["a", 1, "b", "c", 2]
        in [*, String, String, *]
          "matched"
        else
          "not matched"
        end
      CODE
      node = parse(code).in_statements[0].expression
      expect(node.elements).to eq node.children
    end

    it 'gets for dstr node' do
      node = parse('"foo#{bar}baz"')
      expect(node.elements).to eq node.children
    end

    it 'gets for dsym node' do
      node = parse(':"foo#{bar}baz"')
      expect(node.elements).to eq node.children
    end

    it 'gets for xstr node' do
      node = parse('`foo#{bar}baz`')
      expect(node.elements).to eq node.children
    end

    it 'gets for regexp do' do
      node = parse('/foo#{bar}baz/im')
      expect(node.elements).to eq node.children[0...-1]
    end

    it 'gets for regopt node' do
      node = parse('/foo#{bar}baz/im').options
      expect(node.elements).to eq [:i, :m]
    end

    it 'gets for masgn node' do
      node = parse('a, b = 1, 2').variable
      expect(node.elements).to eq node.children
    end

    it 'gets for undef node' do
      node = parse('undef foo, bar')
      expect(node.elements).to eq node.children
    end
  end

  describe '#options' do
    it 'gets for regexp do' do
      node = parse('/foo#{bar}baz/im')
      expect(node.options).to eq node.children[-1]
    end
  end

  describe '#exceptions' do
    it 'gets for resbody node' do
      code = <<~CODE
        begin
          foobar
        rescue Exception, A => bar
          1
        end
      CODE
      node = parse(code).children.first.rescue_bodies.first
      expect(node.exceptions).to eq parse('[Exception, A]')
    end
  end

  describe '#to_value' do
    it 'gets for int' do
      node = parse('1')
      expect(node.to_value).to eq 1
    end

    it 'gets for float' do
      node = parse('1.5')
      expect(node.to_value).to eq 1.5
    end

    it 'gets for string' do
      node = parse("'str'")
      expect(node.to_value).to eq 'str'
    end

    it 'gets for symbol' do
      node = parse(':str')
      expect(node.to_value).to eq :str
    end

    it 'gets for boolean' do
      node = parse('true')
      expect(node.to_value).to be_truthy
      node = parse('false')
      expect(node.to_value).to be_falsey
    end

    it 'gets for nil' do
      node = parse('nil')
      expect(node.to_value).to be_nil
    end

    it 'gets for array' do
      node = parse("['str', :str]")
      expect(node.to_value).to eq ['str', :str]
    end
  end

  describe '#to_source' do
    it 'gets for node' do
      source = 'params[:user][:email]'
      node = parse(source)
      expect(node.to_source).to eq 'params[:user][:email]'
    end
  end

  describe 'pair node by method_missing' do
    it 'gets for pair node' do
      node = parse('{:foo => :bar}')
      expect(node.foo_pair.to_source).to eq ':foo => :bar'

      node = parse("{'foo' => 'bar'}")
      expect(node.foo_pair.to_source).to eq "'foo' => 'bar'"

      expect(node.bar_pair).to be_nil
    end
  end

  describe 'pair value node by method_missing' do
    it 'gets for pair value node' do
      node = parse('{:foo => :bar}')
      expect(node.foo_value).to eq parse(':bar')

      node = parse("{'foo' => 'bar'}")
      expect(node.foo_value).to eq parse("'bar'")

      expect(node.bar_value).to be_nil
    end
  end

  describe 'key value source by method_missing' do
    it 'gets for key value source' do
      node = parse('{:foo => :bar}')
      expect(node.foo_source).to eq ':bar'

      node = parse("{'foo' => 'bar'}")
      expect(node.foo_source).to eq "'bar'"

      expect(node.bar_source).to eq ''
    end
  end

  describe 'not supported method' do
    it 'raises MethodNotSupported error' do
      node = parse('class Synvert; end')
      expect { node.message }
        .to raise_error(ParserNodeExt::MethodNotSupported)
    end
  end
end
