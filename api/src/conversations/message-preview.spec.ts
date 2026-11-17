import { previewOf } from './message-preview';

describe('previewOf', () => {
  it('cuts a preview at 60 characters with an ellipsis', () => {
    expect(previewOf('가'.repeat(61))).toBe(`${'가'.repeat(60)}…`);
  });

  it('keeps a 60 character text as it is', () => {
    expect(previewOf('가'.repeat(60))).toBe('가'.repeat(60));
  });

  it('counts an emoji as one character', () => {
    expect(previewOf('😀'.repeat(61))).toBe(`${'😀'.repeat(60)}…`);
  });
});
