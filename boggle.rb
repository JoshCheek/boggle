module Boggle
  extend self

  DICE = [
    %w[A A E E G N],
    %w[A B B J O O],
    %w[A C H O P S],
    %w[A F F K P S],
    %w[A O O T T W],
    %w[C I M O T U],
    %w[D E I L R X],
    %w[D E L R V Y],
    %w[D I S T T Y],
    %w[E E G H N W],
    %w[E E I N S U],
    %w[E H R T V W],
    %w[E I O S S T],
    %w[E L R T T Y],
    %w[H I M N U Qu],
    %w[H L N N R Z],
  ]


  def build_board
    DICE.shuffle.each_slice(4).map { |row| row.map &:sample }
  end


  def word_score(word)
    case word.length
    when 0, 1, 2 then  0
    when 3, 4    then  1
    when 5       then  2
    when 6       then  3
    when 7       then  5
    else              11
    end
  end


  def adjacent?(x1, y1, x2, y2)
    (x1-1==x2 && y1-1==y2) || (x1==x2 && y1-1==y2) || (x1+1==x2 && y1-1==y2) ||
    (x1-1==x2 && y1  ==y2) ||                         (x1+1==x2 && y1  ==y2) ||
    (x1-1==x2 && y1+1==y2) || (x1==x2 && y1+1==y2) || (x1+1==x2 && y1+1==y2)
  end


  def matches(word, chars_to_locations)
    locations = word.map { |char| chars_to_locations[char] }
    return [] unless locations.any? && locations.all?
    first = locations.first.map { |l| [l] }
    rest  = locations.drop 1

    rest.reduce first do |word_matches, char_matches|
      word_matches.each_with_object [] do |word_match, next_word_matches|
        char_matches.each do |char_match|
          next unless adjacent? *word_match.last, *char_match
          next if word_match.include? char_match
          next_word_matches << (word_match + [char_match])
        end
      end
    end
  end



  def chars_to_locations(board)
    board.flat_map
         .with_index { |row, y| row.map.with_index { |c, x| [c, x, y] } }
         .group_by { |char, *| char }
         .each { |_c, matches| matches.each &:shift }
  end

  def interrupt?(char)
    return false if char.empty?
    char.ord == 3
  end

  def eos?(char)
    return false if char.empty?
    char.ord == 4 # C-d
  end

  def quit?(char)
    return true if interrupt? char
    return true if eos? char
    false
  end

  def cancel_guess?(word, char)
    return false if char.empty?
    return true  if char.ord == 0x15
    return false if word.empty?
    interrupt? char
  end

  def submit_guess?(char)
    char == "\r" || char == "\n"
  end

  def delete?(char)
    return false if char.empty?
    char.ord == 0x7F
  end

  def guess?(char)
    !(char.to_s.match /[a-z]/i).nil?
  end
end
