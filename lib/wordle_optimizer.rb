# frozen_string_literal: true

require 'httparty'
require 'json'
require 'date'

class WordleOptimizer
  def initialize
    @solutions_dir = File.join(Dir.pwd, 'solutions')
    @used_words = File.readlines('used-up-to-2025-06-01.txt').map(&:strip)
    @unused_words = File.readlines('unused.txt').map(&:strip)
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
    date = most_recent_solution_date || Date.today - 1
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
    @eligible_words = @unused_words - @used_words
    @eligible_words -= Dir.glob(File.join(@solutions_dir, '*.json')).map do |file|
      JSON.parse(File.read(file))['solution']
    end
  end

  def score_words
    @scores = @eligible_words.map do |word|
      [word, score_word(word)]
    end.sort_by { |_, score| -score }
  end

  def score_word(word)
    solutions = Dir.glob(File.join(@solutions_dir, '*.json')).map do |file|
      JSON.parse(File.read(file))['solution']
    end

    solutions.sum do |solution|
      score_against_solution(word, solution)
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
