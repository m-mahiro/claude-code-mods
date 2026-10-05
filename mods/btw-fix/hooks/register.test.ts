import { test, expect } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'

const ZERO_USAGE = {
  input_tokens: 0,
  output_tokens: 0,
  cache_read_input_tokens: 0,
  cache_creation_input_tokens: 0,
}

const runBtw = ($: Engine, args: string) =>
  $.command.run({
    command: 'btw',
    args,
    origin: { kind: 'composer' },
    presentation: { isFullscreen: false, columns: 80 },
  })

test('answers from conversation context, with no next() to the native panel', async ($, on) => {
  on('ui.toast', () => ({ value: undefined }))
  on('model.fork', ($, e) => {
    expect(e.prompt).toBe('what does this mean?')
    return { value: { isAnswered: true, text: 'A quick answer.', usage: ZERO_USAGE } }
  })

  const result = await runBtw($, 'what does this mean?')

  expect(result.text).toBe('A quick answer.')
})

test('shows usage text when asked with no question', async $ => {
  const result = await runBtw($, '')

  expect(result.text).toContain('Usage:')
})

test('explains when there is nothing to fork yet', async ($, on) => {
  on('ui.toast', () => ({ value: undefined }))
  on('model.fork', () => ({ value: { isAnswered: false, reason: 'nothing-to-fork' } }))

  const result = await runBtw($, 'hello')

  expect(result.text).toContain('nothing to go on yet')
})

test('explains when the fork was interrupted', async ($, on) => {
  on('ui.toast', () => ({ value: undefined }))
  on('model.fork', () => ({ value: { isAnswered: false, reason: 'aborted', usage: ZERO_USAGE } }))

  const result = await runBtw($, 'hello')

  expect(result.text).toContain('interrupted')
})
