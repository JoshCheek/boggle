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


def adjacent?(prevx, prevy, newx, newy)
  (prevx-1 == newx && prevy-1 == newy) ||
  (prevx   == newx && prevy-1 == newy) ||
  (prevx+1 == newx && prevy-1 == newy) ||
  (prevx-1 == newx && prevy   == newy) ||
  (prevx+1 == newx && prevy   == newy) ||
  (prevx-1 == newx && prevy+1 == newy) ||
  (prevx   == newx && prevy+1 == newy) ||
  (prevx+1 == newx && prevy+1 == newy)
end


def matches(word, chars_to_locations)
  chars_to_matches = word.map { |char| chars_to_locations[char] }
  return [] unless chars_to_matches.any?
  return [] unless chars_to_matches.all?
  word_matches = chars_to_matches.shift.map { |char_match| [char_match] }

  chars_to_matches.each do |char_matches|
    new_word_matches = []
    word_matches.each do |word_match|
      prevx, prevy = word_match.last
      char_matches.each do |char_match|
        newx, newy = char_match
        next unless adjacent? prevx, prevy, newx, newy
        next if word_match.include? char_match
        new_word_matches << (word_match + [char_match])
      end
    end
    word_matches = new_word_matches
  end

  word_matches
end


def show_board(board, path, heads)
  str = ""
  board.map.with_index do |row, y|
    str << "\e[#{y+1}H"
    row.each.with_index do |char, x|
      cell = [x, y]
      if heads.include? cell
        colour_on  = "\e[46;95m"
      elsif path.include? cell
        colour_on  = "\e[35m"
      end
      colour_off = "\e[0m"
      padding    = ""
      padding    = " " unless char.length == 2 # line them up with 2 chars b/c of "Qu"
      str << "#{colour_on}#{char}#{colour_off}#{padding} "
    end
    str << "\r\n"
  end
  str
end

def build_board
  DICE.shuffle.each_slice(4).map { |row| row.map &:sample }
end

def chars_to_locations(board)
  board.flat_map
       .with_index { |row, y| row.map.with_index { |c, x| [c, x, y] } }
       .group_by { |char, *| char }
       .each { |_c, matches| matches.map &:shift }
       .to_h
end


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
