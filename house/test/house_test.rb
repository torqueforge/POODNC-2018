require_relative '../../test_helper'
require_relative '../lib/house'

class PhrasesDouble
  def data
    ['1a 1b', '2a 2b', '3a 3b', 'the house that Jack built']
  end
end

class HouseTest < Minitest::Test
  attr_reader :tale
  def setup
    @tale   = CumulativeTale.new(phrases: PhrasesDouble.new)
  end

  def test_line_1
    expected = "This is the house that Jack built.\n"
    assert_equal expected, tale.line(1)
  end

  def test_line_2
    expected = "This is 3a 3b the house that Jack built.\n"
    assert_equal expected, tale.line(2)
  end

  def test_line_3
    expected = "This is 2a 2b 3a 3b the house that Jack built.\n"
    assert_equal expected, tale.line(3)
  end

  def test_line_4
    expected = "This is 1a 1b 2a 2b 3a 3b the house that Jack built.\n"
    assert_equal expected, tale.line(4)
  end

  def test_all_the_lines
    expected = <<-TEXT
This is the house that Jack built.

This is 3a 3b the house that Jack built.

This is 2a 2b 3a 3b the house that Jack built.

This is 1a 1b 2a 2b 3a 3b the house that Jack built.
    TEXT
    assert_equal expected, tale.recite
  end
end


class RandomOrdererTest < Minitest::Test
  def test_lines
   Random.srand(1)
   data     = [['1a', nil, '1c'], ['2a', '2b', '2c'], ['3a', '3b'], ['the house', 'that Jack built']]
   expected = [["the house", "that Jack built"], ["3a", "3b"], ["1a", nil, "1c"], ["2a", "2b", "2c"]]
   assert_equal expected, RandomOrderer.new.order(data)
 end
end

class FixedLastRandomOrdererTest < Minitest::Test
  def test_lines
   Random.srand(1)
   data     = [['1a', nil, '1c'], ['2a', '2b', '2c'], ['3a', '3b'], ['the house', 'that Jack built']]
   expected = [["1a", nil, "1c"], ["3a", "3b"], ["2a", "2b", "2c"], ["the house", "that Jack built"]]
   assert_equal expected, FixedLastRandomOrderer.new.order(data)
 end
end

class MixedActorActionOrdererTest < Minitest::Test
  def test_lines
    Random.srand(1)
    data     = [['1a', nil, '1c'], ['2a', '2b', '2c'], ['3a', '3b', '3c'], ['the house', nil, 'that Jack built']]
    expected = [["the house", nil, "that Jack built"], ["3a", "3b", "3c"], ["1a", "2b", "1c"], ["2a", nil, "2c"]]
    assert_equal expected, MixedActorActionOrderer.new.order(data)
  end
end

class FixedLastRightMixedActorActionOrdererTest < Minitest::Test
  def test_lines
    Random.srand(1)
    data     = [['1a', nil, '1c'], ['2a', '2b', '2c'], ['3a', '3b', '3c'], ['the house', nil, 'that Jack built']]
    expected = [["the house", nil, "1c"], ["3a", "3b", "3c"], ["1a", "2b", "2c"], ["2a", nil, "that Jack built"]]
    assert_equal expected, FixedLastRightMixedActorActionOrderer.new.order(data)
  end
end


class UnchangedOrdererTest < Minitest::Test
  def test_lines
    data     = [["1a", nil, "1c"], ["3a", "3b"], ["2a", "2b", "2c"], ["the house", "that Jack built"]]
    expected = data
    assert_equal expected, UnchangedOrderer.new.order(data)
  end
end

class PhrasesTest < Minitest::Test
  def test_phrases
    data     = [['1a', '1b'], ['2a', '2b'], ['3a', '3b'], ['the house', 'that Jack built']]
    expected = ['1a 1b', '2a 2b', '3a 3b', 'the house that Jack built']
    assert_equal expected, Phrases.new(list: data).data
  end

  def test_default_phrases
    data     = ["the horse and the hound and the horn that belonged to", "the farmer sowing his corn that kept", "the rooster that crowed in the morn that woke", "the priest all shaven and shorn that married", "the man all tattered and torn that kissed", "the maiden all forlorn that milked", "the cow with the crumpled horn that tossed", "the dog that worried", "the cat that killed", "the rat that ate", "the malt that lay in", "the house that Jack built"]
    expected = data
    assert_equal expected, Phrases.new.data
  end
end