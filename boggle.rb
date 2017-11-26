require 'set'
require 'io/console'


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

def matches(chars_to_locations, word)
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
        next unless (prevx-1 == newx && prevy-1 == newy) ||
                    (prevx   == newx && prevy-1 == newy) ||
                    (prevx+1 == newx && prevy-1 == newy) ||
                    (prevx-1 == newx && prevy   == newy) ||
                    (prevx+1 == newx && prevy   == newy) ||
                    (prevx-1 == newx && prevy+1 == newy) ||
                    (prevx   == newx && prevy+1 == newy) ||
                    (prevx+1 == newx && prevy+1 == newy)
        next if word_match.include? char_match
        new_word_matches << (word_match + [char_match])
      end
    end
    word_matches = new_word_matches
  end

  word_matches
end


def show_board(board, coloured_locations)
  str = ""
  board.map.with_index do |row, y|
    str << "\e[#{y+1}H"
    row.each.with_index do |char, x|
      if coloured_locations.include? [x, y]
        colour_on  = "\e[46;97m"
        colour_off = "\e[0m"
      end
      padding = ""
      padding = " " unless char.length == 2 # line them up with 2 chars b/c of "Qu"
      str << "#{colour_on}#{char}#{colour_off}#{padding} "
    end
    str << "\r\n"
  end
  str
end

dice = [
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

board = nil
loop do
  board = dice.shuffle.each_slice(4).map { |row| row.map(&:sample) }
  chars = board.flatten.map(&:downcase)
  break if ARGV.all? { |char| chars.include? char.downcase }
end

char_locations = board.flat_map.with_index do |row, y|
  row.map.with_index { |char, x| [char, x, y] }
end
chars_to_locations = char_locations.group_by do |char, *|
  char
end.map do |char, matches|
  [char, matches.map { |_char, x, y| [x, y] }]
end.to_h

word       = []
words      = []
start      = Time.now
speed      = 1
over       = false
red        = 91
orange     = 93
green      = 32
prev_print = {}

# hide / show cursor
print "\e[?25l"
at_exit { print "\e[?25h" }


# clear the screen
print "\e[H\e[2J"


# read chars instead of lines
$stdin.raw!
at_exit { $stdin.cooked! }


until over
  to_print = ""

  # read input
  (readable, *), (writable, *) = IO.select [$stdin], [$stdout]
  if readable
    readable.readpartial(100).chars.each do |char|
      # Quit on C-c and C-d
      if char.ord == 3 || char.ord == 4
        over = true
      # Return submits theword
      elsif char == "\r" || char == "\n"
        matches = matches(chars_to_locations, word)
        words << word if matches.any? && !words.include?(word)
        word = []
      # b/c "Qu" is grouped as a single char, check for that case
      elsif (char == "u" || char == "U") && word.last == "Q"
        word.last << "u"
      # delete
      elsif char.ord == 0x7F
        word.last == 'Qu' ?  word[-1] = 'Q' : word.pop
      # okay, it's a normal character submission
      else
        word << char.upcase
      end
    end
  end

  # quit if we're out of time
  seconds      = Time.now - start
  time_allowed = 60 * 3
  time_passed  = (speed * seconds).to_i
  time_left    = time_allowed - time_passed
  over         = true if time_left < 0 # allow 1s grace :)
  time_left    = 0    if time_left < 0 # but report it as still being at zero

  # skip the rest of this if nothing has changed
  next_print = {
    word:      word.dup,
    words:     words.dup,
    time_left: time_left,
  }
  if prev_print == next_print
    sleep 0.1
    next
  else
    prev_print = next_print
  end

  # find matches
  matches = matches(chars_to_locations, word)
  coloured_locations = Set.new matches.flat_map { |w| w }

  # clear screen
  to_print << "\e[H\e[2J"

  # print the time
  colour = time_left <= 10 ? red : time_left <= 30 ? orange : green
  to_print << sprintf("\e[1;13HTime:  \e[#{colour}m%d\e[0m   ", time_left)

  # print the number of words found
  to_print << "\e[2;13HWords: #{words.length}"

  # print the score
  score = words.reduce(0) { |score, word| score + word_score(word) }
  to_print << sprintf("\e[3;13HScore: %d", score)

  # print the board
  to_print << show_board(board, coloured_locations)

  # print the word
  to_print << word.join.downcase << "\r\n"

  # print the words
  to_print << "-----  words  -----\r\n"

  cols, rows = $stdin.winsize
  cols -= 7 # for the stuff previously printed
  xoffset = 1
  words.each_slice(cols) do |word_set|
    max_score = 0
    word_set.each.with_index(8) do |word, yoffset|
      score = word_score(word)
      max_score = score if max_score < score
      to_print << ("\e[#{yoffset};#{xoffset}H%2d %s\r\n" % [
        score, word.join.downcase
      ])
    end
    to_print.chomp! "\r\n"
    xoffset += max_score.to_s.length
    xoffset += word_set.map(&:length).max + 3 # 3 for the gap between words
  end

  print to_print
end

puts "\r\n\n\e[41;97m GAME OVER!! \e[0m\e[J"
puts
