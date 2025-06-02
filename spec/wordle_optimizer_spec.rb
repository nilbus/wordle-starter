require 'spec_helper'
require_relative '../lib/wordle_optimizer'

RSpec.describe WordleOptimizer do
  let(:solutions_dir) { File.join(Dir.pwd, 'solutions') }
  let(:used_words) { %w[apple berry] }
  let(:unused_words) { %w[apple berry crane delta eagle] }
  let(:solutions) { %w[crane delta eagle] }

  before do
    allow(File).to receive(:readlines).with('used-up-to-2025-06-01.txt').and_return(used_words)
    allow(File).to receive(:readlines).with('unused.txt').and_return(unused_words)
    allow(Dir).to receive(:exist?).and_return(true)
    allow(Dir).to receive(:pwd).and_return(Dir.pwd)
    allow(Dir).to receive(:glob).with(File.join(solutions_dir, '*.json')).and_return(solutions.map { |s| File.join(solutions_dir, "2024-06-01.json") })
    allow(File).to receive(:read).and_return('{"solution":"crane"}')
    allow(JSON).to receive(:parse).and_return({ 'solution' => 'crane' })
  end

  describe '#score_against_solution' do
    it 'scores green matches correctly' do
      expect(subject.send(:score_against_solution, 'hello', 'hello')).to eq(15) # 5 green = 15 points
    end

    it 'scores yellow matches correctly' do
      expect(subject.send(:score_against_solution, 'hello', 'world')).to eq(4) # 1 green (3) + 1 yellow (1) = 4 points
    end

    it 'scores mixed matches correctly' do
      expect(subject.send(:score_against_solution, 'hello', 'helps')).to eq(9) # 3 green (9) + 0 yellow (0) = 9 points
    end
  end
end
