# coding: utf-8

# 3/1/2015
# Implements an evaluator for the SIMPLE arithemtic language
# with variables and environments described in chapter 2
# of Understanding Computation.
# Takes some liberties with the implementation but is compatible
# with the examples in the text.
class Expression
  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end
end

class Variable < Expression
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def to_s
    name.to_s
  end

  def reduce(environment)
    environment[name]
  end
end

class Value < Expression
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def to_s
    value.to_s
  end

  def reducible?
    false
  end
end

class Number < Value; end
class Boolean < Value; end

class BinOp < Expression
  attr_reader :op, :left, :right

  def initialize(op, left, right)
    @op, @left, @right  = op, left, right
  end

  def to_s
    "(#{left} #{op} #{right})"
  end

  def reduce(environment)
    if left.reducible?
      self.class.new(left.reduce(environment), right)
    elsif right.reducible?
      self.class.new(left, right.reduce(environment))
    else
      self.class.value_klass.new(left.value.send(op, right.value))
    end
  end
end

class UnaryOp < Expression
  attr_reader :op, :expression

  def initialize(op, expression)
    @op, @expression = op, expression
  end

  def to_s
    "(#{op} #{expression})"
  end

  def reduce(environment)
    if expression.reducible?
      self.class.new(expression.reduce(environment))
    else
      self.class.value_klass.new(expression.value.send(op))
    end
  end
end

class BooleanOp < BinOp
  def self.value_klass
    Boolean
  end
end

class ArithmeticOp < BinOp
  def self.value_klass
    Number
  end
end

class Add < ArithmeticOp
  def initialize(left, right)
    super(:+, left, right)
  end
end

class Multiply < ArithmeticOp
  def initialize(left, right)
    super(:*, left, right)
  end
end

class Subtract < ArithmeticOp
  def initialize(left, right)
    super(:-, left, right)
  end
end

class Divide < ArithmeticOp
  def initialize(left, right)
    super(:/, left, right)
  end
end

class LessThan < BooleanOp
  def initialize(left, right)
    super(:<, left, right)
  end
end

class GreaterThan < BooleanOp
  def initialize(left, right)
    super(:>, left, right)
  end
end

class And < BooleanOp
  def initialize(left, right)
    super("&&".to_sym, left, right)
  end
end

class Or < BooleanOp
  def initialize(left, right)
    super("||".to_sym, left, right)
  end
end

class Not < UnaryOp
  def initialize(expression)
    super("!".to_sym, expression)
  end

  def self.value_klass
    Boolean
  end
end

class Machine
  attr_reader :expression, :steps, :environment

  def initialize(expression, environment)
    @steps = [expression]
    @expression = expression
    @environment = environment
  end

  def run
    while steps.last.reducible?
      self.steps << steps.last.reduce(environment)
    end
    puts steps.map(&:inspect)
    steps.last
  end
end
