/**
 * @file NodeInfo.test.js
 * @project DEMOS Node Dashboard
 * @repository https://github.com/weudlll-cyber/demos-dashboard
 *
 * @description
 *   Component test suite for NodeInfo.svelte.
 *   Renders the component in a happy-dom environment using
 *   @testing-library/svelte and verifies the rendered DOM output.
 *
 * @coverage
 *   - Renders the card title 'Node Info'
 *   - Displays version, version name, and connection string
 *   - Truncates long identity to 42 chars + ellipsis
 *   - Does NOT truncate identity strings under 42 chars
 *   - Shows '\u2014' for every missing / undefined field
 *
 * @props
 *   data {object}  Full node response object passed as component prop.
 *
 * @testFramework  Vitest 1.x + @testing-library/svelte 4.x
 * @environment    happy-dom
 *
 * @author  weudlll-cyber
 * @license MIT
 */

import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import NodeInfo from './NodeInfo.svelte';

const FULL_DATA = {
  version: '0.9.8',
  version_name: 'Oxlong Michael',
  identity: '0xd9409b0d6106e5358b29a56bd4957a1f31fa1a192f00b85cb02709170447f4ab',
  connectionString: 'http://localhost:53550',
};

describe('NodeInfo', () => {
  it('renders the card title', () => {
    render(NodeInfo, { props: { data: FULL_DATA } });
    expect(screen.getByText('Node Info')).toBeTruthy();
  });

  it('displays the version', () => {
    render(NodeInfo, { props: { data: FULL_DATA } });
    expect(screen.getByText('0.9.8')).toBeTruthy();
  });

  it('displays the version name', () => {
    render(NodeInfo, { props: { data: FULL_DATA } });
    expect(screen.getByText('Oxlong Michael')).toBeTruthy();
  });

  it('displays the connection string', () => {
    render(NodeInfo, { props: { data: FULL_DATA } });
    expect(screen.getByText('http://localhost:53550')).toBeTruthy();
  });

  it('truncates a long identity to 42 chars + ellipsis', () => {
    render(NodeInfo, { props: { data: FULL_DATA } });
    const expected = FULL_DATA.identity.slice(0, 42) + '…';
    expect(screen.getByText(expected)).toBeTruthy();
  });

  it('does not truncate a short identity', () => {
    const shortId = '0xabc123';
    render(NodeInfo, { props: { data: { ...FULL_DATA, identity: shortId } } });
    expect(screen.getByText(shortId)).toBeTruthy();
  });

  it('shows dashes for missing fields', () => {
    render(NodeInfo, { props: { data: {} } });
    const dashes = screen.getAllByText('—');
    // version, version_name, connectionString, identity => at least 4 dashes
    expect(dashes.length).toBeGreaterThanOrEqual(4);
  });
});
