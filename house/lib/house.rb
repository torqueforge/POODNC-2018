class Phrases
  DATA =
    [ "the horse and the hound and the horn that belonged to",
      "the farmer sowing his corn that kept",
      "the rooster that crowed in the morn that woke",
      "the priest all shaven and shorn that married",
      "the man all tattered and torn that kissed",
      "the maiden all forlorn that milked",
      "the cow with the crumpled horn that tossed",
      "the dog that worried",
      "the cat that killed",
      "the rat that ate",
      "the malt that lay in",
      "the house that Jack built"]
  attr_reader :data

  def initialize(orderer: UnchangedOrderer.new, list: DATA)
    @data = orderer.order(list)
  end
end


class CumulativeTale
  attr_reader :data, :prefix

  def initialize(phrases: Phrases.new, prefixer: NormalPrefixer.new)
    @data = phrases.data
    @prefix = prefixer.prefix
  end

  def recite
    1.upto(data.size).collect {|i| line(i)}.join("\n")
  end

  def phrase(num=1)
    data.last(num).join(" ")
  end

  def line(num)
    "#{prefix} #{phrase(num)}.\n"
  end
end


class RandomOrderer
  def order(data)
    data.shuffle
  end
end

class UnchangedOrderer
  def order(data)
    data
  end
end

class FixedLastRandomOrderer
  def order(data)
    data[0..-2].shuffle << data[-1]
  end
end

class NormalPrefixer
  def prefix
    "This is"
  end
end

class PiratePrefixer
  def prefix
    "Thar be"
  end
end

puts CumulativeTale.new(
        phrases: Phrases.new(orderer: FixedLastRandomOrderer.new),
        prefixer: PiratePrefixer.new).line(12)
puts