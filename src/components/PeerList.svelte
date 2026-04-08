<!--
  @file PeerList.svelte
  @project DEMOS Node Dashboard
  @repository https://github.com/weudlll-cyber/demos-dashboard

  @description
    Renders a full-width scrollable table listing every peer returned by the
    DEMOS node API. Each row shows all available status fields for that peer.

    Identity values are shortened with shortId() for display; the complete
    identity is accessible as an HTML title tooltip.

    The table wrapper has overflow-x:auto so the layout stays intact on
    narrow screens without horizontal page overflow.

  @props
    peers {Array}  The peerlist array from the node response.
                  Defaults to [] so the empty-state message renders safely
                  before any data arrives.

  @author  weudlll-cyber
  @license MIT
-->
<script>
  import Tooltip from './Tooltip.svelte';

  export let peers = [];

  // Shortens a peer identity hex string to 'first10…10…last6' for table display.
  // Full value is kept in the HTML title attribute for hover/copy access.
  function shortId(id) {
    if (!id) return '—';
    // Show first 10 and last 6 chars for readability
    return id.length > 20 ? id.slice(0, 10) + '…' + id.slice(-6) : id;
  }
</script>

<div class="card">
  <div class="card-header">
    <div class="card-header-left">
      <span class="card-title">Peer List</span>
      <Tooltip text="Other DEMOS nodes that this node is currently connected to. More peers means better network participation and more reliable data." />
    </div>
    <span
      class="peer-count"
      title="Number of other DEMOS nodes currently connected to this node"
    >{peers?.length ?? 0} peer{(peers?.length ?? 0) !== 1 ? 's' : ''}</span>
  </div>

  {#if !peers || peers.length === 0}
    <p style="color: var(--text-muted); font-size: 0.85rem;">No peers connected.</p>
  {:else}
    <div style="overflow-x: auto;">
      <table class="peer-table">
        <thead>
          <tr>
            <th class="hide-mobile">#</th>
            <th><span class="th-inner">Identity <Tooltip text="The unique cryptographic ID of this peer node. Each node has a different one. Hover the value in the row to see the full ID." /></span></th>
            <th class="hide-mobile"><span class="th-inner">Connection <Tooltip text="The network address (IP and port) used to reach this peer." /></span></th>
            <th><span class="th-inner">Online <Tooltip text="Whether this peer is currently reachable on the network." /></span></th>
            <th><span class="th-inner">Ready <Tooltip text="Whether this peer has finished starting up and is ready to process blocks." /></span></th>
            <th><span class="th-inner">Synced <Tooltip text="Whether this peer's blockchain is up to date with the rest of the network." /></span></th>
            <th><span class="th-inner">Block <Tooltip text="The latest block number this peer has processed. Should match the block height shown in Sync Status when fully synced." /></span></th>
            <th class="hide-mobile"><span class="th-inner">Verified <Tooltip text="Whether this peer's blockchain data has passed cryptographic verification checks." /></span></th>
          </tr>
        </thead>
        <tbody>
          {#each peers as peer, i}
            <tr>
              <td class="hide-mobile">{i + 1}</td>
              <td class="mono" title={peer.identity}>{shortId(peer.identity)}</td>
              <td class="mono hide-mobile">{peer.connection?.string ?? '—'}</td>
              <td>
                <span class="pill {peer.status?.online ? 'ok' : 'err'}">
                  {peer.status?.online ? 'Yes' : 'No'}
                </span>
              </td>
              <td>
                <span class="pill {peer.status?.ready ? 'ok' : 'warn'}">
                  {peer.status?.ready ? 'Yes' : 'No'}
                </span>
              </td>
              <td>
                <span class="pill {peer.sync?.status ? 'ok' : 'err'}">
                  {peer.sync?.status ? 'Yes' : 'No'}
                </span>
              </td>
              <td>{peer.sync?.block?.toLocaleString() ?? '—'}</td>
              <td class="hide-mobile">
                <span class="pill {peer.verification?.status ? 'ok' : 'warn'}">
                  {peer.verification?.status ? 'Yes' : 'No'}
                </span>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</div>
