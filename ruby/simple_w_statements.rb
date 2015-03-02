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

  def ==(other_value)
    value == other_value.value
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

class Statement
  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end
end

class DoNothing < Statement
  def to_s
    'do-nothing'
  end

  def ==(statement)
    statement.instance_of?(DoNothing)
  end

  def reducible?
    false
  end
end

class Sequence < Statement
  attr_reader :first, :second

  def initialize(first, second)
    @first, @second = first, second
  end

  def to_s
    "#{first}; #{second}"
  end

  def reduce(environment)
    case first
    when DoNothing.new
      [second, environment]
    else
      reduced_first, reduced_environment = first.reduce(environment)
      [Sequence.new(reduced_first, second), reduced_environment]
    end
  end
end

class While < Statement
  attr_reader :condition, :body

  def initialize(condition, body)
    @condition, @body = condition, body
  end

  def to_s
    "while (#{condition}) { #{body} }"
  end

  def reduce(environment)
    [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
  end
end

class If < Statement
  attr_reader :condition, :consequence, :alternative

  def initialize(condition, consequence, alternative)
    @condition, @consequence, @alternative = condition, consequence, alternative
  end

  def to_s
    "if (#{condition}) { #{consequence} } else { #{alternative} }"
  end

  def reduce(environment)
    if condition.reducible?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    else
      case condition
      when Boolean.new(true)
        [consequence, environment]
      when Boolean.new(false)
        [alternative, environment]
      end
    end
  end
end

class Assign < Statement
  attr_reader :name, :expression
  def initialize(name, expression)
    @name, @expression = name, expression
  end

  def to_s
    "#{name} := #{expression}"
  end

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge({ name => expression })]
    end
  end
end

class Machine
  attr_reader :statement, :steps, :environment

  def initialize(statement, environment)
    @steps = [[statement, environment]]
    @statement = statement
    @environment = environment
  end

  def run
    while steps.last[0].reducible?
      statement, environment = steps.last[0].reduce(steps.last[1])
      @steps << [statement, environment]
    end
    steps.each do |(s, e)|
      puts "#{s}, #{e}"
    end
    steps.last[1]
  end
end
