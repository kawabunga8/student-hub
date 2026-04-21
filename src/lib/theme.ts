/*
 * RCS design tokens — JS mirror of public/rcs-theme.css
 * Use this for inline `style` props in React components.
 * For CSS classes, link to /rcs-theme.css and use the .rcs-* classes.
 */

export const RCS = {
  deepNavy:  '#1F4E79',
  midBlue:   '#2E75B6',
  lightBlue: '#D6E4F0',
  gold:      '#C9A84C',
  paleGold:  '#FDF3DC',
  white:     '#FFFFFF',
  textDark:  '#1A1A1A',
  bg:        '#F0F4F8',
} as const;

export type RCSColor = typeof RCS[keyof typeof RCS];
