# frozen_string_literal: true

require 'httparty'
require 'json'
require 'date'
require 'set'

class WordleOptimizer
  LETTER_FREQUENCIES = {
    'e' => 12.7, 't' => 9.1, 'a' => 8.2, 'o' => 7.5, 'i' => 7.0, 'n' => 6.7,
    's' => 6.3, 'h' => 6.1, 'r' => 6.0, 'd' => 4.3, 'l' => 4.0, 'c' => 2.8,
    'u' => 2.8, 'm' => 2.4, 'w' => 2.4, 'f' => 2.2, 'g' => 2.0, 'y' => 2.0,
    'p' => 1.9, 'b' => 1.5, 'v' => 1.0, 'k' => 0.8, 'j' => 0.15, 'x' => 0.15,
    'q' => 0.10, 'z' => 0.07
  }.freeze

  def initialize
    @solutions_dir = File.join(Dir.pwd, 'solutions')
    @used_word_pool = File.readlines('used-up-to-2025-06-01.txt').map(&:strip)
    @original_unused_wordle_pool = File.readlines('unused.txt').map(&:strip)
    ensure_solutions_dir
  end

  def run(show_top_100: false)
    download_future_solutions
    filter_eligible_words
    score_words
    display_results(show_top_100)
  end

  private

  def ensure_solutions_dir
    Dir.mkdir(@solutions_dir) unless Dir.exist?(@solutions_dir)
  end

  def download_future_solutions
    date = most_recent_solution_date || Date.new(2025, 6, 1) # most recent in used-up-to-2025-06-01.txt
    loop do
      date += 1
      solution = fetch_solution(date)
      break unless solution
      save_solution(date, solution)
    end
  end

  def most_recent_solution_date
    dates = Dir.glob(File.join(@solutions_dir, '*.json')).map do |file|
      Date.parse(File.basename(file, '.json'))
    end
    dates.max
  end

  def fetch_solution(date)
    url = "https://www.nytimes.com/svc/wordle/v2/#{date.strftime('%Y-%m-%d')}.json"
    response = HTTParty.get(url)
    return if response.code == 404
    STDERR.puts "Found solution for #{date}"
    JSON.parse(response.body)['solution']
  end

  def save_solution(date, solution)
    File.write(
      File.join(@solutions_dir, "#{date.strftime('%Y-%m-%d')}.json"),
      { solution: solution }.to_json
    )
  end

  def filter_eligible_words
    @eligible_words = @original_unused_wordle_pool + @used_word_pool
    @eligible_words -= recent_solutions # avoid win in 1
  end

  def score_words
    @scores = @eligible_words.map do |word|
      [word, score_word(word)]
    end.sort_by { |_, score| -score }
  end

  def score_word(word)
    base_score = recent_solutions.sum do |solution|
      score_against_solution(word, solution)
    end

    # Add a bonus for words with unique letters
    # The bonus is 10% of the base score if all letters are unique
    unique_letters_bonus = word.chars.uniq.length == 5 ? base_score * 0.1 : 0

    # Add letter frequency bonus (smaller than the unique letters bonus to maintain primary scoring)
    # We use the average frequency of the letters in the word
    frequency_bonus = word.chars.map { |c| LETTER_FREQUENCIES[c] || 0 }.sum / 5.0
    frequency_bonus = frequency_bonus * 0.05  # Scale down to 5% of the frequency score

    base_score + unique_letters_bonus + frequency_bonus
  end

  def recent_solutions
    @recent_solutions ||= Dir.glob(File.join(@solutions_dir, '*.json')).map do |file|
      JSON.parse(File.read(file))['solution']
    end
  end

  def score_against_solution(word, solution)
    guess = word.chars
    answer = solution.chars
    guess_used = Array.new(5, false)
    answer_used = Array.new(5, false)
    green_matches = 0
    yellow_matches = 0

    # First pass: greens
    5.times do |i|
      if guess[i] == answer[i]
        green_matches += 1
        guess_used[i] = true
        answer_used[i] = true
      end
    end

    # Second pass: yellows
    5.times do |i|
      next if guess_used[i]
      5.times do |j|
        next if answer_used[j]
        if guess[i] == answer[j]
          yellow_matches += 1
          guess_used[i] = true
          answer_used[j] = true
          break
        end
      end
    end

    green_matches * 3 + yellow_matches
  end

  def display_results(show_top_100 = false)
    if show_top_100
      puts "\nTop 100 optimal starting words:"
      puts "----------------------------"
      @scores.first(100).each_with_index do |(word, score), i|
        puts "#{i + 1}. #{word.upcase} (Score: #{score})"
      end
    else
      puts "\nOptimal starting word pair:"
      puts "----------------------------"

      top_word = @scores.first[0]
      puts "1. #{top_word.upcase} (Score: #{@scores.first[1]})"

      # Find the next best word that shares no letters with the top word
      top_word_chars = top_word.chars.to_set
      next_word = @scores[1..].find { |word, _| (word.chars.to_set & top_word_chars).empty? }

      if next_word
        puts "2. #{next_word[0].upcase} (Score: #{next_word[1]})"
      else
        puts "No suitable second word found that shares no letters with #{top_word.upcase}"
      end
    end
  end
end
