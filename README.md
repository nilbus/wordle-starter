# Wordle Starter Word Optimizer

This tool helps find optimal starting words for Wordle by analyzing historical and future solutions. It uses a sophisticated scoring algorithm to evaluate potential starting words against known and upcoming Wordle solutions.

## Features

- Downloads and maintains a database of historical Wordle solutions
- Fetches upcoming solutions from the NYT API
- Scores potential starting words based on their effectiveness against future solutions
- Excludes previously used words and upcoming solutions from consideration
- Provides detailed scoring and optimization results

## Installation

```bash
git clone https://github.com/yourusername/wordle-starter.git
cd wordle-starter
bundle install
```

## Usage

```bash
bin/wordle-optimize-starter
```

## Development

The project uses RSpec for testing. Run the test suite with:

```bash
bundle exec rspec
```

## Project Structure

- `bin/` - Executable scripts
- `lib/` - Core library code
- `spec/` - Test files
- `solutions/` - Cached Wordle solutions
- `used-up-to-2025-06-01.txt` - Historical Wordle solutions
- `unused.txt` - Pool of potential starting words

## License

MIT
