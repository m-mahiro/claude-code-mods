import type { Register } from 'claude-code'

// The built-in /btw opens a blocking side panel: the main transcript can't be
// scrolled while it's pending, and closing the panel cancels the answer.
// Answering `command.run` here ourselves (without calling `next`) shadows
// that built-in behavior entirely — our `{ text }` prints as a normal
// transcript row instead, so there's nothing to lock the screen or to close.
export const register: Register = on => {
  on('command.run', { command: 'btw' }, async ($, e) => {
    const question = e.args.trim()

    if (question === '') {
      return {
        text: 'Usage: /btw <question> — answers a quick side question from the current conversation, without opening a side panel.',
      }
    }

    $.ui.toast('💭 /btw: answering…')

    const result = await $.model.fork({ prompt: question })

    if (result.isAnswered) return { text: result.text }

    switch (result.reason) {
      case 'nothing-to-fork':
        return { text: '/btw has nothing to go on yet — send a message first.' }
      case 'empty-reply':
        return { text: '/btw got no answer back.' }
      case 'aborted':
        return { text: '/btw was interrupted.' }
      case 'api-error':
        return { text: `/btw failed to reach the model (${result.error}).` }
    }
  })
}
