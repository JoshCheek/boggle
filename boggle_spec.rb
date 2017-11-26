require_relative 'boggle'

RSpec.describe 'Boggle' do
  describe 'word_score' do
    specify('length 0  is worth  0') { expect(word_score '').to eq 0 }
    specify('length 1  is worth  0') { expect(word_score 'a').to eq 0 }
    specify('length 2  is worth  0') { expect(word_score 'aa').to eq 0 }
    specify('length 3  is worth  1') { expect(word_score 'aaa').to eq 1 }
    specify('length 4  is worth  1') { expect(word_score 'aaaa').to eq 1 }
    specify('length 5  is worth  2') { expect(word_score 'aaaaa').to eq 2 }
    specify('length 6  is worth  3') { expect(word_score 'aaaaaa').to eq 3 }
    specify('length 7  is worth  5') { expect(word_score 'aaaaaaa').to eq 5 }
    specify('length >7 is worth 11') do
      expect(word_score   'aaaaaaaa').to eq 11
      expect(word_score  'aaaaaaaaa').to eq 11
      expect(word_score 'aaaaaaaaaa').to eq 11
    end
  end


  describe 'adjacent?' do
    specify('false when 2 to the top left')   { expect(adjacent? 5, 5, 3, 3).to eq false }
    specify('true  when 1 to the top left')   { expect(adjacent? 5, 5, 4, 4).to eq true }
    specify('true  when 1 to the top')        { expect(adjacent? 5, 5, 5, 4).to eq true }
    specify('true  when 1 to the top right')  { expect(adjacent? 5, 5, 6, 4).to eq true }
    specify('false when 2 to the top right')  { expect(adjacent? 5, 5, 7, 3).to eq false }

    specify('false when 2 to the left')        { expect(adjacent? 5, 5, 3, 5).to eq false }
    specify('true  when 1 to the left')        { expect(adjacent? 5, 5, 4, 5).to eq true }
    specify('false when at the same location') { expect(adjacent? 5, 5, 5, 5).to eq false }
    specify('true  when 1 to the right')       { expect(adjacent? 5, 5, 6, 5).to eq true }
    specify('false when 2 to the right')       { expect(adjacent? 5, 5, 7, 5).to eq false }

    specify('false when 2 to the bot right')  { expect(adjacent? 5, 5, 3, 7).to eq false }
    specify('true  when 1 to the bot left')   { expect(adjacent? 5, 5, 4, 6).to eq true }
    specify('true  when 1 to the bot')        { expect(adjacent? 5, 5, 5, 6).to eq true }
    specify('true  when 1 to the bot right')  { expect(adjacent? 5, 5, 6, 6).to eq true }
    specify('false when 2 to the bot right')  { expect(adjacent? 5, 5, 7, 7).to eq false }
  end


  describe 'matches' do
    it 'finds matches through adjacent chars' do
      matches = matches(
        %w[a b c],
        'a' => [[1, 1]],
        'b' => [[2, 1]],
        'c' => [[3, 1]],
      )
      expect(matches).to eq [
        [[1, 1], [2, 1], [3, 1]]
      ]
    end

    it 'allows multiple matches' do
      matches = matches(
        %w[a b c],
        'a' => [[1, 1], [2, 2]],
        'b' => [[2, 1]],
        'c' => [[3, 1]],
      )
      expect(matches).to eq [
        [[1, 1], [2, 1], [3, 1]],
        [[2, 2], [2, 1], [3, 1]],
      ]
    end

    it 'does not traverse the same char more than once' do
      matches1 = matches %w[a b a], 'a' => [[1, 1]],         'b' => [[2, 1]]
      matches2 = matches %w[a b a], 'a' => [[1, 1], [2, 2]], 'b' => [[2, 1]]
      expect(matches1).to eq []
      expect(matches2).to eq [
        [[1, 1], [2, 1], [2, 2]],
        [[2, 2], [2, 1], [1, 1]],
      ]
    end

    it 'does not find paths through non-adjacent chars' do
      matches = matches(
        %w[a b c],
        'a' => [[1, 1]],
        'b' => [[1, 2],
                [3, 2]],
        'c' => [[3, 1]],
      )
      expect(matches).to eq []
    end

    it 'does not find paths for chars that DNE in the list' do
      matches = matches(%w[a b a], 'a' => [[1, 1]], 'c' => [[3, 1]])
      expect(matches).to eq []
    end
  end


  describe 'dice' do
    specify 'there are 16 of them' do
      expect(DICE.length).to eq 16
    end

    specify 'they each have 6 sides' do
      DICE.each do |die|
        expect(die.length).to eq 6
      end
    end

    specify 'every character is present, including qu' do
      chars = DICE.flatten.uniq
      expect(chars).to include 'Qu'
      'A'.upto('Z') do |char|
        if char == 'Q'
          expect(chars).to include 'Qu'
        else
          expect(chars).to include char
        end
      end
    end
  end


  describe 'build_board' do
    it 'builds a 4x4 board from the dice' do
      board = build_board
      expect(board.length).to eq 4
      board.each { |row| expect(row.length).to eq 4 }
      dice_chars = DICE.flatten
      board.flatten.all? do |face|
        expect(dice_chars).to include face
      end
    end

    it 'is random' do
      expect(build_board).to_not eq build_board
    end
  end


  describe 'chars_to_locations' do
    it 'has keys of the characters on the board' do
      board       = build_board
      board_chars = board.flatten.uniq
      keys        = chars_to_locations(board).keys
      keys.each { |key| expect(board_chars).to include key }
    end

    it 'has values of the locations of those characters' do
      board = build_board
      chars_to_locations(board).each do |char, locations|
        locations.each do |x, y|
          expect(board[y][x]).to eq char
        end
      end
    end
  end


  describe 'input evaluation' do
    specify "quit? is true for C-c and C-d" do
      expect(quit? "\u0003".encode("ascii-8bit")).to eq true
      expect(quit? "\u0003").to eq true
      expect(quit? "\u0004".encode("ascii-8bit")).to eq true
      expect(quit? "\u0004").to eq true
      expect(quit? "\u0002").to eq false
      expect(quit? "\u0005").to eq false
      expect(quit?       "").to eq false
    end

    specify 'submit_guess? is true for return' do
      expect(submit_guess? "\r").to eq true
      expect(submit_guess? "\n").to eq true
      expect(submit_guess?   "").to eq false
      expect(submit_guess?  "x").to eq false
    end

    specify 'delete? is true for 0x7F and C-u' do
      expect(delete? "\u007f".encode("ascii-8bit")).to eq true
      expect(delete? "\u007f").to eq true
      expect(delete? "").to eq false
      expect(delete? "x").to eq false
    end

    specify 'guess? is true for a-z, A-Z' do
      "a".upto "z" do |char|
        expect(guess? char.downcase).to eq true
        expect(guess? char.upcase).to eq true
      end
      expect(guess?  ".").to eq false
      expect(guess?  "[").to eq false
      expect(guess? "\e").to eq false
      expect(guess?   "").to eq false
      expect(guess?  nil).to eq false
    end

    specify 'cancel_guess? is true for C-u, or C-c when there is input' do
      expect(cancel_guess? [], ?\C-u.encode("ascii-8bit")).to eq true
      expect(cancel_guess? [], ?\C-u).to eq true
      expect(cancel_guess? ['a'], ?\C-u).to eq true
      expect(cancel_guess? ['a'], ?\C-c.encode("ascii-8bit")).to eq true
      expect(cancel_guess? ['a'], ?\C-c).to eq true
      expect(cancel_guess? [], ?\C-c.encode("ascii-8bit")).to eq false
      expect(cancel_guess? [], ?\C-c).to eq false
      expect(cancel_guess? [], 'x').to eq false
      expect(cancel_guess? ['a'], 'x').to eq false
      expect(cancel_guess? [], '').to eq false
      expect(cancel_guess? ['a'], '').to eq false
    end
  end


end
