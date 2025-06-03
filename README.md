# Wordle Starter Word Optimizer

This app provides a daily optimal start word for Wordle.

Possible start words include previous Wordle solutions and previously-planned
future solutions back in Oct 2022 when Wordle switched to editor-driven solutions.
(Since then, solutions are only planned and known days to weeks in advance.)

This app optimizes a start word for all known future solutions in the upcoming
weeks but will never suggest an actual correct solution, which would ruin the fun.

Specifically, it scores a point for every yellow, 3 points for every green,
and bonuses for having all unique letters and for containing frequently-used
letters, averaged over the all the upcoming words.

Last, it provides an optimal second word in case the first word has no matches.
Even with matches, a variant that shares its letters may be a good second word.

## Features

- Fetches upcoming solutions from the NYT API
- Scores potential starting words based on their effectiveness against future solutions
- Excludes upcoming solutions from consideration
- Provides detailed scoring and optimization results

## Web Worker (Cloudflare)

### Development

This project runs as a Cloudflare Worker. It can run locally using wrangler.

```bash
npm install -g wrangler

wrangler dev # run a local server
```

Visit `http://localhost:8787/` to see the top word and fallback word
Visit `http://localhost:8787/?100` to see the top 100 words

## Ruby CLI

### Installation

```bash
bundle install
```

### Usage

```bash
bin/wordle-optimize-starter # Show the top start word and fallback second word
bin/wordle-optimize-starter --100 # show top 100 scoring start words
```

### Development

The project uses RSpec for testing. Run the test suite with:

```bash
bundle exec rspec
```

## License

MIT
